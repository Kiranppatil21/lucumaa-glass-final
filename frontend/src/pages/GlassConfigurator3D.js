import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import * as BABYLON from '@babylonjs/core';
import '@babylonjs/loaders';
import { AdvancedDynamicTexture, TextBlock, Control, Line, Button as BabylonButton } from '@babylonjs/gui';
import earcut from 'earcut';
import { QRCodeSVG } from 'qrcode.react';
import { 
  Package, Ruler, Palette, Circle, Square, RectangleHorizontal,
  Plus, Minus, Trash2, Move, ZoomIn, ZoomOut, RotateCcw,
  FileText, ShoppingCart, Loader2, Triangle, ChevronDown,
  Hexagon, Heart, RotateCw, MousePointer, GripVertical,
  Copy, Grid3X3, LayoutTemplate, Magnet, FileDown, Eye, Crosshair,
  Printer, Download, Settings2, Share2, MessageCircle, Mail, Link2, X, QrCode,
  CornerDownRight, PenTool, Maximize2, RotateCcw as Rotate3D, Pencil, Minimize2,
  Star, Octagon, Diamond
} from 'lucide-react';
import { Button } from '../components/ui/button';
import { toast } from 'sonner';

import { API_ROOT } from '../utils/apiBase';

const API_URL = API_ROOT;

// Cut-out shape types
const CUTOUT_SHAPES = [
  { id: 'SH', name: 'Hole', icon: Circle, label: 'H', defaultSize: { diameter: 50 } },
  { id: 'R', name: 'Rectangle', icon: RectangleHorizontal, label: 'R', defaultSize: { width: 100, height: 80 } },
  { id: 'T', name: 'Triangle', icon: Triangle, label: 'T', defaultSize: { width: 100, height: 80 } },
  { id: 'HX', name: 'Hexagon', icon: Hexagon, label: 'HX', defaultSize: { diameter: 60 } },
  { id: 'HR', name: 'Heart', icon: Heart, label: 'HR', defaultSize: { diameter: 60 } },
  { id: 'ST', name: 'Star', icon: Star, label: 'ST', defaultSize: { diameter: 70 } },
  { id: 'PT', name: 'Pentagon', icon: Hexagon, label: 'PT', defaultSize: { diameter: 60 } },
  { id: 'OV', name: 'Oval', icon: Circle, label: 'OV', defaultSize: { width: 100, height: 60 } },
  { id: 'DM', name: 'Diamond', icon: Diamond, label: 'DM', defaultSize: { width: 70, height: 70 } },
  { id: 'OC', name: 'Octagon', icon: Octagon, label: 'OC', defaultSize: { diameter: 60 } },
  { id: 'CN', name: 'Corner Notch', icon: Square, label: 'CN', defaultSize: { width: 80, height: 80 }, isCorner: true },
  { id: 'PG', name: 'Custom Polygon', icon: Hexagon, label: 'PG', defaultSize: { points: [] }, isCustom: true },
];

// Corner positions for corner notch
const CORNER_POSITIONS = [
  { id: 'TL', name: 'Top-Left', anchor: { x: 0, y: 1 } },
  { id: 'TR', name: 'Top-Right', anchor: { x: 1, y: 1 } },
  { id: 'BL', name: 'Bottom-Left', anchor: { x: 0, y: 0 } },
  { id: 'BR', name: 'Bottom-Right', anchor: { x: 1, y: 0 } },
];

// Common hole sizes for quick selection (in mm)
const PRESET_HOLE_SIZES = [5, 8, 10, 12, 14, 16, 20, 25, 30, 40, 50];

// Snap grid sizes (in mm)
const SNAP_GRID_SIZES = [5, 10, 20, 50];

// Cutout templates - pre-saved configurations
const CUTOUT_TEMPLATES = [
  { 
    id: 'handle_hole', 
    name: 'Door Handle Hole', 
    type: 'SH', 
    diameter: 35,
    description: 'Standard door handle cutout'
  },
  { 
    id: 'hinge_cutout', 
    name: 'Hinge Cutout', 
    type: 'R', 
    width: 80, 
    height: 25,
    description: 'Standard hinge placement'
  },
  { 
    id: 'lock_cutout', 
    name: 'Lock Cutout', 
    type: 'R', 
    width: 25, 
    height: 150,
    description: 'Mortise lock cutout'
  },
  { 
    id: 'cable_hole', 
    name: 'Cable Pass-through', 
    type: 'SH', 
    diameter: 50,
    description: 'Cable management hole'
  },
  { 
    id: 'vent_hole', 
    name: 'Ventilation Hole', 
    type: 'SH', 
    diameter: 25,
    description: 'Small ventilation cutout'
  }
];

// Door Fittings Templates - specific positions for door glass
const DOOR_FITTINGS = [
  // --- HANDLES ---
  {
    id: 'door_handle_center',
    name: 'Handle - Center',
    type: 'SH',
    diameter: 35,
    position: { xPercent: 0.85, yPercent: 0.5 },
    description: 'Door handle hole (center position)',
    icon: '🚪',
    category: 'handle'
  },
  {
    id: 'door_handle_upper',
    name: 'Handle - Upper',
    type: 'SH',
    diameter: 35,
    position: { xPercent: 0.85, yPercent: 0.65 },
    description: 'Door handle hole (upper position)',
    icon: '🔼',
    category: 'handle'
  },
  {
    id: 'door_handle_lower',
    name: 'Handle - Lower',
    type: 'SH',
    diameter: 35,
    position: { xPercent: 0.85, yPercent: 0.35 },
    description: 'Door handle hole (lower position)',
    icon: '🔽',
    category: 'handle'
  },
  // --- LOCKS ---
  {
    id: 'lock_center',
    name: 'Lock - Center',
    type: 'R',
    width: 25,
    height: 120,
    position: { xPercent: 0.12, yPercent: 0.5 },
    description: 'Mortise lock cutout',
    icon: '🔒',
    category: 'lock'
  },
  {
    id: 'lock_floor',
    name: 'Lock - Floor Level',
    type: 'R',
    width: 30,
    height: 80,
    position: { xPercent: 0.5, yPercent: 0.08 },
    description: 'Floor bolt lock cutout',
    icon: '🔐',
    category: 'lock'
  },
  // --- HINGES ---
  {
    id: 'hinge_top',
    name: 'Hinge - Top',
    type: 'R',
    width: 80,
    height: 25,
    position: { xPercent: 0.08, yPercent: 0.92 },
    description: 'Top hinge cutout',
    icon: '📎',
    category: 'hinge'
  },
  {
    id: 'hinge_middle',
    name: 'Hinge - Middle',
    type: 'R',
    width: 80,
    height: 25,
    position: { xPercent: 0.08, yPercent: 0.5 },
    description: 'Middle hinge cutout',
    icon: '📎',
    category: 'hinge'
  },
  {
    id: 'hinge_bottom',
    name: 'Hinge - Bottom',
    type: 'R',
    width: 80,
    height: 25,
    position: { xPercent: 0.08, yPercent: 0.08 },
    description: 'Bottom hinge cutout',
    icon: '📎',
    category: 'hinge'
  },
  // --- FLOOR SPRING / PIVOT ---
  {
    id: 'floor_spring_center',
    name: 'Floor Spring - Center',
    type: 'R',
    width: 50,
    height: 180,
    position: { xPercent: 0.5, yPercent: 0.08 },
    description: 'Floor spring mechanism cutout',
    icon: '⚙️',
    category: 'floor_spring'
  },
  {
    id: 'floor_pivot_bottom',
    name: 'Floor Pivot Hole',
    type: 'SH',
    diameter: 25,
    position: { xPercent: 0.5, yPercent: 0.03 },
    description: 'Floor machine pivot hole',
    icon: '⬇️',
    category: 'floor_spring'
  },
  {
    id: 'floor_pivot_top',
    name: 'Top Pivot Hole',
    type: 'SH',
    diameter: 25,
    position: { xPercent: 0.5, yPercent: 0.97 },
    description: 'Top pivot/closer hole',
    icon: '⬆️',
    category: 'floor_spring'
  },
];

// Production mode colors for different cutout types
const CUTOUT_COLORS = {
  SH: { normal: '#3B82F6', highlight: '#60A5FA', name: 'Blue' },      // Hole - Blue
  R: { normal: '#22C55E', highlight: '#4ADE80', name: 'Green' },      // Rectangle - Green
  T: { normal: '#F59E0B', highlight: '#FBBF24', name: 'Orange' },     // Triangle - Orange
  HX: { normal: '#8B5CF6', highlight: '#A78BFA', name: 'Purple' },    // Hexagon - Purple
  HR: { normal: '#EC4899', highlight: '#F472B6', name: 'Pink' },      // Heart - Pink
  ST: { normal: '#FBBF24', highlight: '#FCD34D', name: 'Yellow' },    // Star - Yellow
  PT: { normal: '#06B6D4', highlight: '#22D3EE', name: 'Cyan' },      // Pentagon - Cyan
  OV: { normal: '#A855F7', highlight: '#C084FC', name: 'Violet' },    // Oval - Violet
  DM: { normal: '#F97316', highlight: '#FB923C', name: 'Amber' },     // Diamond - Amber
  OC: { normal: '#10B981', highlight: '#34D399', name: 'Emerald' },   // Octagon - Emerald
  CN: { normal: '#EF4444', highlight: '#F87171', name: 'Red' },       // Corner Notch - Red
  PG: { normal: '#14B8A6', highlight: '#2DD4BF', name: 'Teal' },      // Custom Polygon - Teal
};

// View modes
const VIEW_MODES = {
  NORMAL: 'normal',
  HIGH_CONTRAST: 'high_contrast',
  PRODUCTION: 'production',
};

// Default glass item
const createDefaultGlassItem = (id) => ({
  id,
  name: `Glass ${id}`,
  glass_type: 'toughened',
  thickness_mm: 8,
  color_id: 'clear',
  color_name: 'Clear',
  color_hex: '#E8E8E8',
  application: 'window',
  width_mm: 900,
  height_mm: 600,
  cutouts: [],
  quantity: 1,
  item_price: 0
});

const GlassConfigurator3D = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  
  // Canvas and engine refs - NEVER recreate
  const canvasRef = useRef(null);
  const engineRef = useRef(null);
  const sceneRef = useRef(null);
  const cameraRef = useRef(null);
  const guiTextureRef = useRef(null);
  
  // FIXED glass mesh - created once, never recreated
  const glassMeshRef = useRef(null);
  const glassMaterialRef = useRef(null);
  const glassCreatedRef = useRef(false);
  
  // Dimension labels for glass (static - created once)
  const widthLabelRef = useRef(null);
  const heightLabelRef = useRef(null);
  const heightLabelRightRef = useRef(null); // Right side height label
  
  // Shape meshes and their attached elements
  const cutoutMeshesRef = useRef(new Map()); // Map of cutoutId -> mesh
  const cutoutLabelsRef = useRef(new Map()); // Map of cutoutId -> labels array
  const handleMeshesRef = useRef([]);
  
  // Interaction refs
  const isDraggingRef = useRef(false);
  const dragTypeRef = useRef(null); // 'move', 'resize', 'rotate'
  const dragDataRef = useRef(null);
  const lastPointerRef = useRef({ x: 0, y: 0 });
  const dragStartPosRef = useRef(null);
  const pendingDragRef = useRef(false);
  
  // State
  const [glassItems, setGlassItems] = useState([createDefaultGlassItem(1)]);
  const [activeItemIndex, setActiveItemIndex] = useState(0);
  const [pricingConfig, setPricingConfig] = useState(null);
  const [pricingRules, setPricingRules] = useState({ price_per_sqft: 300, cutout_price: 50 });
  const [loading, setLoading] = useState(true);
  const [selectedCutoutId, setSelectedCutoutId] = useState(null);
  const [selectedCutoutType, setSelectedCutoutType] = useState('SH');
  const [isPlacementMode, setIsPlacementMode] = useState(false);
  
  // Snap-to-grid state
  const [snapEnabled, setSnapEnabled] = useState(false);
  const [snapGridSize, setSnapGridSize] = useState(10); // mm
  
  // Templates panel
  const [showTemplates, setShowTemplates] = useState(false);
  const [orderTotal, setOrderTotal] = useState(0);
  const [calculatingPrice, setCalculatingPrice] = useState(false);

  // Current config (must be defined before any pricing helpers that read it)
  const config = glassItems[activeItemIndex] || createDefaultGlassItem(1);
  
  // Real-time price calculation for ALL glass items
  const calculateLivePrice = () => {
    let grandTotal = 0;
    let itemsBreakdown = [];
    
    glassItems.forEach((item, idx) => {
      if (!item.width_mm || !item.height_mm || item.cutouts.length === 0) {
        return;
      }
      
      const width_ft = item.width_mm / 304.8;
      const height_ft = item.height_mm / 304.8;
      const area_sqft = width_ft * height_ft;
      const basePrice = area_sqft * (pricingRules?.price_per_sqft ?? 300);
      const cutoutCharge = item.cutouts.length * (pricingRules?.cutout_price ?? 50);
      const quantity = item.quantity || 1;
      const itemTotal = (basePrice + cutoutCharge) * quantity;
      
      grandTotal += itemTotal;
      itemsBreakdown.push({
        index: idx + 1,
        area_sqft,
        basePrice,
        cutoutCharge,
        quantity,
        itemTotal
      });
    });
    
    const advanceAmount = grandTotal * 0.5;
    return { grandTotal, advanceAmount, itemsBreakdown };
  };
  
  const livePrice = calculateLivePrice();
  
  // Current item price for display
  const currentItemPrice = () => {
    if (!config.width_mm || !config.height_mm || config.cutouts.length === 0) {
      return { basePrice: 0, cutoutCharge: 0, totalAmount: 0, area_sqft: 0 };
    }
    const width_ft = config.width_mm / 304.8;
    const height_ft = config.height_mm / 304.8;
    const area_sqft = width_ft * height_ft;
    const basePrice = area_sqft * (pricingRules?.price_per_sqft ?? 300);
    const cutoutCharge = config.cutouts.length * (pricingRules?.cutout_price ?? 50);
    const quantity = config.quantity || 1;
    const totalAmount = (basePrice + cutoutCharge) * quantity;
    return { basePrice, cutoutCharge, totalAmount, area_sqft };
  };
  
  const currentPrice = currentItemPrice();
  const [generatingQuotation, setGeneratingQuotation] = useState(false);
  
  // Production mode state
  const [viewMode, setViewMode] = useState(VIEW_MODES.NORMAL);
  const [addingToOrder, setAddingToOrder] = useState(false);
  const [orderModalOpen, setOrderModalOpen] = useState(false);
  const [showGrid, setShowGrid] = useState(false);
  const [showCenterMarks, setShowCenterMarks] = useState(true);
  const [showDimensionLines, setShowDimensionLines] = useState(true);
  const [showCutoutNumbers, setShowCutoutNumbers] = useState(true);
  const [exportingPDF, setExportingPDF] = useState(false);
  
  // Share functionality state
  const [showShareModal, setShowShareModal] = useState(false);
  const [shareUrl, setShareUrl] = useState('');
  const [creatingShareLink, setCreatingShareLink] = useState(false);
  
  // 3D View rotation state
  const [viewAngle, setViewAngle] = useState({ alpha: -Math.PI / 2, beta: Math.PI / 2 }); // Default: front view
  const [isLargePreview, setIsLargePreview] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  
  // Polygon drawing state
  const [isDrawingPolygon, setIsDrawingPolygon] = useState(false);
  const [polygonPoints, setPolygonPoints] = useState([]);
  
  // Corner notch state
  const [selectedCorner, setSelectedCorner] = useState('TL');
  
  // Measurement tool state
  const [isMeasuring, setIsMeasuring] = useState(false);
  const [measurePoints, setMeasurePoints] = useState([]); // Array of {pointA, pointB, distance} objects
  const [currentMeasurePoint, setCurrentMeasurePoint] = useState(null); // First point while measuring
  
  // Dropdown open states
  const [openDropdown, setOpenDropdown] = useState(null);
  
  
  // Grid overlay ref
  const gridLinesRef = useRef([]);
  
  // Glass edges ref (for 3D border effect)
  const glassEdgesRef = useRef([]);
  
  // Refs for latest state in event handlers
  const activeItemIndexRef = useRef(activeItemIndex);
  const selectedCutoutIdRef = useRef(selectedCutoutId);
  const isPlacementModeRef = useRef(isPlacementMode);
  const selectedCutoutTypeRef = useRef(selectedCutoutType);
  const configRef = useRef(config);
  const snapEnabledRef = useRef(snapEnabled);
  const snapGridSizeRef = useRef(snapGridSize);
  const isDrawingPolygonRef = useRef(isDrawingPolygon);
  const polygonPointsRef = useRef(polygonPoints);
  const selectedCornerRef = useRef(selectedCorner);
  const isMeasuringRef = useRef(isMeasuring);
  const currentMeasurePointRef = useRef(currentMeasurePoint);
  
  // Measurement lines refs (for Babylon.js meshes)
  const measurementLinesRef = useRef([]);
  
  // Polygon drawing preview refs
  const polygonPreviewMeshesRef = useRef([]);
  
  useEffect(() => { activeItemIndexRef.current = activeItemIndex; }, [activeItemIndex]);
  useEffect(() => { selectedCutoutIdRef.current = selectedCutoutId; }, [selectedCutoutId]);
  useEffect(() => { isPlacementModeRef.current = isPlacementMode; }, [isPlacementMode]);
  useEffect(() => { selectedCutoutTypeRef.current = selectedCutoutType; }, [selectedCutoutType]);
  useEffect(() => { configRef.current = config; }, [config]);
  useEffect(() => { snapEnabledRef.current = snapEnabled; }, [snapEnabled]);
  useEffect(() => { snapGridSizeRef.current = snapGridSize; }, [snapGridSize]);
  useEffect(() => { isDrawingPolygonRef.current = isDrawingPolygon; }, [isDrawingPolygon]);
  useEffect(() => { polygonPointsRef.current = polygonPoints; }, [polygonPoints]);
  useEffect(() => { selectedCornerRef.current = selectedCorner; }, [selectedCorner]);
  useEffect(() => { isMeasuringRef.current = isMeasuring; }, [isMeasuring]);
  useEffect(() => { currentMeasurePointRef.current = currentMeasurePoint; }, [currentMeasurePoint]);

  // Get selected cutout
  const selectedCutout = config.cutouts.find(c => c.id === selectedCutoutId);

  // Update current item helper
  const updateCurrentItem = useCallback((updates) => {
    setGlassItems(prev => prev.map((item, idx) => 
      idx === activeItemIndex ? { ...item, ...updates } : item
    ));
  }, [activeItemIndex]);

  // Scale calculation - FIXED VERTICAL visual size
  // Glass always shown as fixed vertical (portrait) rectangle
  const getScale = useCallback(() => {
    // Fixed visual dimensions - glass always appears this size
    const fixedVisualHeight = 380; // Vertical (tall)
    const fixedVisualWidth = 280;  // Narrower
    
    // Scale converts mm to visual pixels
    // Use height-based scale for vertical orientation
    const scaleX = fixedVisualWidth / config.width_mm;
    const scaleY = fixedVisualHeight / config.height_mm;
    
    // Use the smaller scale to ensure everything fits
    return Math.min(scaleX, scaleY);
  }, [config.width_mm, config.height_mm]);

  // Fetch pricing config
  useEffect(() => {
    fetchPricingConfig();
  }, []);

  // Fetch pricing rules (₹/sqft and ₹/cutout)
  useEffect(() => {
    fetchPricingRules();
  }, []);

  const fetchPricingRules = async () => {
    try {
      const token = localStorage.getItem('token');
      const headers = token ? { 'Authorization': `Bearer ${token}` } : {};
      const response = await fetch(`${API_URL}/settings/pricing`, { headers });
      if (!response.ok) return;
      const data = await response.json();
      if (typeof data?.price_per_sqft === 'number' && typeof data?.cutout_price === 'number') {
        setPricingRules({ price_per_sqft: data.price_per_sqft, cutout_price: data.cutout_price });
      }
    } catch (error) {
      // Keep defaults if fetch fails
      console.warn('Failed to fetch pricing rules:', error);
    }
  };

  const fetchPricingConfig = async () => {
    try {
      const response = await fetch(`${API_URL}/erp/glass-config/pricing`);
      const data = await response.json();
      setPricingConfig(data);
    } catch (error) {
      console.error('Failed to fetch pricing:', error);
      // Fallback config
      setPricingConfig({
        glass_types: [
          { glass_type: 'toughened', display_name: 'Toughened', base_price_per_sqft: 85, active: true },
          { glass_type: 'laminated', display_name: 'Laminated', base_price_per_sqft: 120, active: true },
          { glass_type: 'frosted', display_name: 'Frosted', base_price_per_sqft: 95, active: true },
        ],
        thickness_options: [
          { thickness_mm: 5, display_name: '5mm', price_multiplier: 1.0, active: true },
          { thickness_mm: 6, display_name: '6mm', price_multiplier: 1.1, active: true },
          { thickness_mm: 8, display_name: '8mm', price_multiplier: 1.25, active: true },
          { thickness_mm: 10, display_name: '10mm', price_multiplier: 1.4, active: true },
          { thickness_mm: 12, display_name: '12mm', price_multiplier: 1.6, active: true },
        ],
        colors: [
          { color_id: 'clear', color_name: 'Clear', hex_code: '#E8E8E8', price_percentage: 0, active: true },
          { color_id: 'grey', color_name: 'Grey', hex_code: '#808080', price_percentage: 10, active: true },
          { color_id: 'bronze', color_name: 'Bronze', hex_code: '#CD7F32', price_percentage: 15, active: true },
          { color_id: 'blue', color_name: 'Blue', hex_code: '#4169E1', price_percentage: 15, active: true },
          { color_id: 'green', color_name: 'Green', hex_code: '#228B22', price_percentage: 15, active: true },
        ],
        applications: [
          { application_id: 'window', application_name: 'Window', price_multiplier: 1.0, active: true },
          { application_id: 'door', application_name: 'Door', price_multiplier: 1.0, active: true },
          { application_id: 'partition', application_name: 'Partition', price_multiplier: 1.0, active: true },
          { application_id: 'railing', application_name: 'Railing', price_multiplier: 1.1, active: true },
          { application_id: 'shower', application_name: 'Shower Enclosure', price_multiplier: 1.15, active: true },
        ],
        hole_cutout_pricing: [
          { shape: 'circle', base_price: 30, size_slabs: [{ min_mm: 0, max_mm: 100, price: 50 }], active: true },
          { shape: 'rectangle', base_price: 50, size_slabs: [{ min_mm: 0, max_mm: 200, price: 80 }], active: true },
        ],
        gst_rate: 18
      });
    } finally {
      setLoading(false);
    }
  };

  // Initialize Babylon.js scene - ONCE only
  useEffect(() => {
    if (!canvasRef.current || loading) return;
    if (engineRef.current) return; // Already initialized

    const engine = new BABYLON.Engine(canvasRef.current, true, { 
      preserveDrawingBuffer: true, 
      stencil: true,
      antialias: true
    });
    engineRef.current = engine;

    const scene = new BABYLON.Scene(engine);
    scene.clearColor = new BABYLON.Color4(0.96, 0.97, 0.98, 1);
    sceneRef.current = scene;

    // Camera - orthographic for 2D-like view
    const camera = new BABYLON.ArcRotateCamera(
      'camera',
      -Math.PI / 2,
      Math.PI / 2,
      1000,
      BABYLON.Vector3.Zero(),
      scene
    );
    camera.mode = BABYLON.Camera.ORTHOGRAPHIC_CAMERA;
    camera.orthoLeft = -350;
    camera.orthoRight = 350;
    camera.orthoTop = 280;
    camera.orthoBottom = -280;
    camera.attachControl(canvasRef.current, true);
    camera.wheelPrecision = 10;
    camera.panningSensibility = 0; // Disable panning
    cameraRef.current = camera;

    // Lights
    const light = new BABYLON.HemisphericLight('light', new BABYLON.Vector3(0, 1, 0), scene);
    light.intensity = 1.0;

    // GUI for labels
    const guiTexture = AdvancedDynamicTexture.CreateFullscreenUI('UI', true, scene);
    guiTextureRef.current = guiTexture;

    // Create FIXED glass mesh - will never be recreated
    createGlassMesh(scene);
    
    // Create glass dimension labels - STATIC
    createGlassDimensionLabels(guiTexture);

    // Pointer events with requestAnimationFrame for smooth updates
    scene.onPointerObservable.add((info) => {
      requestAnimationFrame(() => handlePointer(info));
    });

    engine.runRenderLoop(() => scene.render());
    
    const handleResize = () => engine.resize();
    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      guiTexture.dispose();
      engine.dispose();
    };
  }, [loading]);

  // Create FIXED glass mesh - only once
  const createGlassMesh = (scene) => {
    if (glassCreatedRef.current) return;
    
    // Create glass panel with visible edges
    const glass = BABYLON.MeshBuilder.CreateBox('glass', {
      width: 1,
      height: 1,
      depth: 1
    }, scene);

    // Blue transparent glass material
    const glassMat = new BABYLON.StandardMaterial('glassMat', scene);
    glassMat.diffuseColor = new BABYLON.Color3(0.7, 0.85, 0.95); // Light blue tint
    glassMat.alpha = 0.4; // More transparent
    glassMat.specularColor = new BABYLON.Color3(0.8, 0.9, 1.0); // Bluish specular
    glassMat.specularPower = 64; // Shiny glass
    glassMat.backFaceCulling = false;
    glass.material = glassMat;
    
    glass.position = BABYLON.Vector3.Zero();
    glass.isPickable = false;
    
    glassMeshRef.current = glass;
    glassMaterialRef.current = glassMat;
    
    // Create glass edge/border for 3D effect
    createGlassEdges(scene);
    
    glassCreatedRef.current = true;
    
    // Initial sizing
    updateGlassMeshSize();
  };
  
  // Create visible 3D edges around glass
  const createGlassEdges = (scene) => {
    // Edge material - darker blue for visibility
    const edgeMat = new BABYLON.StandardMaterial('edgeMat', scene);
    edgeMat.diffuseColor = new BABYLON.Color3(0.2, 0.4, 0.6);
    edgeMat.emissiveColor = new BABYLON.Color3(0.1, 0.2, 0.3);
    
    // Store edge meshes for later updates
    glassEdgesRef.current = [];
    
    // Create 4 edge bars (will be positioned in updateGlassMeshSize)
    ['top', 'bottom', 'left', 'right'].forEach(pos => {
      const edge = BABYLON.MeshBuilder.CreateBox(`edge_${pos}`, { width: 1, height: 1, depth: 1 }, scene);
      edge.material = edgeMat;
      edge.isPickable = false;
      glassEdgesRef.current.push({ mesh: edge, position: pos });
    });
  };

  // Update glass mesh size - FIXED VERTICAL ORIENTATION
  // Glass always shown vertically (portrait) with fixed visual size
  const updateGlassMeshSize = useCallback(() => {
    if (!glassMeshRef.current) return;
    
    // FIXED visual size - glass always appears this size regardless of actual mm
    // Vertical orientation - height is larger than width visually
    const fixedVisualHeight = 380; // Tall (vertical)
    const fixedVisualWidth = 280;  // Narrower
    const edgeThickness = 6; // 3D edge thickness
    
    // Glass is always shown at fixed visual size
    glassMeshRef.current.scaling.x = fixedVisualWidth;
    glassMeshRef.current.scaling.y = fixedVisualHeight;
    glassMeshRef.current.scaling.z = 8; // Slightly thicker for better visibility
    
    // Update glass edges (3D border effect)
    if (glassEdgesRef.current && glassEdgesRef.current.length === 4) {
      glassEdgesRef.current.forEach(({ mesh, position }) => {
        if (position === 'top') {
          mesh.scaling.set(fixedVisualWidth + edgeThickness * 2, edgeThickness, 10);
          mesh.position.set(0, fixedVisualHeight / 2 + edgeThickness / 2, 0);
        } else if (position === 'bottom') {
          mesh.scaling.set(fixedVisualWidth + edgeThickness * 2, edgeThickness, 10);
          mesh.position.set(0, -fixedVisualHeight / 2 - edgeThickness / 2, 0);
        } else if (position === 'left') {
          mesh.scaling.set(edgeThickness, fixedVisualHeight, 10);
          mesh.position.set(-fixedVisualWidth / 2 - edgeThickness / 2, 0, 0);
        } else if (position === 'right') {
          mesh.scaling.set(edgeThickness, fixedVisualHeight, 10);
          mesh.position.set(fixedVisualWidth / 2 + edgeThickness / 2, 0, 0);
        }
      });
    }
    
    // Update material - blue tint based on selected color
    if (glassMaterialRef.current) {
      const baseColor = config.color_hex || '#B8D4E8';
      // Make it more blue/transparent for glass look
      glassMaterialRef.current.diffuseColor = BABYLON.Color3.FromHexString(baseColor);
      glassMaterialRef.current.alpha = 0.35;
    }
    
    // Update dimension labels
    updateGlassDimensionLabels();
  }, [config.width_mm, config.height_mm, config.color_hex]);

  // Create static glass dimension labels - WIDTH above, HEIGHT on both sides (LARGER & CLEARER)
  const createGlassDimensionLabels = (gui) => {
    // Width label (ABOVE glass - top) - BIGGER
    const widthLabel = new TextBlock('widthLabel');
    widthLabel.text = `◀─── ${config.width_mm} mm ───▶`;
    widthLabel.color = '#0066CC';
    widthLabel.fontSize = 18;
    widthLabel.fontWeight = 'bold';
    widthLabel.outlineWidth = 4;
    widthLabel.outlineColor = 'white';
    widthLabel.top = '-230px';
    widthLabel.verticalAlignment = Control.VERTICAL_ALIGNMENT_CENTER;
    gui.addControl(widthLabel);
    widthLabelRef.current = widthLabel;

    // Height label LEFT side - BIGGER
    const heightLabelLeft = new TextBlock('heightLabelLeft');
    heightLabelLeft.text = `▲ ${config.height_mm} mm ▼`;
    heightLabelLeft.color = '#0066CC';
    heightLabelLeft.fontSize = 18;
    heightLabelLeft.fontWeight = 'bold';
    heightLabelLeft.outlineWidth = 4;
    heightLabelLeft.outlineColor = 'white';
    heightLabelLeft.rotation = -Math.PI / 2;
    heightLabelLeft.left = '-195px';
    heightLabelLeft.horizontalAlignment = Control.HORIZONTAL_ALIGNMENT_CENTER;
    gui.addControl(heightLabelLeft);
    heightLabelRef.current = heightLabelLeft;
    
    // Height label RIGHT side - BIGGER
    const heightLabelRight = new TextBlock('heightLabelRight');
    heightLabelRight.text = `▲ ${config.height_mm} mm ▼`;
    heightLabelRight.color = '#0066CC';
    heightLabelRight.fontSize = 18;
    heightLabelRight.fontWeight = 'bold';
    heightLabelRight.outlineWidth = 4;
    heightLabelRight.outlineColor = 'white';
    heightLabelRight.rotation = Math.PI / 2;
    heightLabelRight.left = '195px';
    heightLabelRight.horizontalAlignment = Control.HORIZONTAL_ALIGNMENT_CENTER;
    gui.addControl(heightLabelRight);
    heightLabelRightRef.current = heightLabelRight;
  };

  // Update glass dimension labels text only
  const updateGlassDimensionLabels = useCallback(() => {
    if (widthLabelRef.current) {
      widthLabelRef.current.text = `◀─── ${config.width_mm} mm ───▶`;
    }
    if (heightLabelRef.current) {
      heightLabelRef.current.text = `▲ ${config.height_mm} mm ▼`;
    }
    if (heightLabelRightRef.current) {
      heightLabelRightRef.current.text = `▲ ${config.height_mm} mm ▼`;
    }
  }, [config.width_mm, config.height_mm]);

  // Update only when glass size/color changes
  useEffect(() => {
    if (sceneRef.current && glassMeshRef.current) {
      updateGlassMeshSize();
    }
  }, [config.width_mm, config.height_mm, config.color_hex, updateGlassMeshSize]);

  // Update cutout visuals without touching glass
  useEffect(() => {
    if (sceneRef.current && guiTextureRef.current) {
      updateCutoutVisuals();
    }
  }, [config.cutouts, selectedCutoutId]);

  // Update cutout meshes and labels - WITHOUT touching glass
  const updateCutoutVisuals = useCallback(() => {
    const scene = sceneRef.current;
    const gui = guiTextureRef.current;
    if (!scene || !gui) return;

    const scale = getScale();
    const currentCutoutIds = new Set(config.cutouts.map(c => c.id));
    
    // Remove old cutouts that no longer exist
    cutoutMeshesRef.current.forEach((mesh, id) => {
      if (!currentCutoutIds.has(id)) {
        mesh.dispose();
        cutoutMeshesRef.current.delete(id);
      }
    });
    
    // Remove old labels
    cutoutLabelsRef.current.forEach((labels, id) => {
      if (!currentCutoutIds.has(id)) {
        labels.forEach(l => l.dispose());
        cutoutLabelsRef.current.delete(id);
      }
    });

    // Remove handles
    handleMeshesRef.current.forEach(h => h.dispose());
    handleMeshesRef.current = [];

    // Create/update each cutout with index for numbering
    config.cutouts.forEach((cutout, index) => {
      createOrUpdateCutoutMesh(cutout, scale, scene);
      createOrUpdateCutoutLabels(cutout, scale, gui, index);
      
      // Create handles for selected cutout
      if (cutout.id === selectedCutoutIdRef.current) {
        createHandles(cutout, scale, scene);
      }
    });
    
    // Handle grid overlay - create if enabled, clear if disabled
    if (showGrid) {
      createGridOverlay(scale, scene);
    } else {
      // Clear grid when disabled
      gridLinesRef.current.forEach(line => line.dispose());
      gridLinesRef.current = [];
    }
  }, [config.cutouts, selectedCutoutId, getScale, showGrid, viewMode, showCenterMarks, showDimensionLines, showCutoutNumbers]);

  // Render polygon preview while drawing
  useEffect(() => {
    const scene = sceneRef.current;
    if (!scene) return;
    
    // Clear previous preview meshes
    polygonPreviewMeshesRef.current.forEach(mesh => mesh.dispose());
    polygonPreviewMeshesRef.current = [];
    
    if (!isDrawingPolygon || polygonPoints.length === 0) return;
    
    const scale = getScale();
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    
    // Create spheres for each point
    polygonPoints.forEach((point, idx) => {
      const sphere = BABYLON.MeshBuilder.CreateSphere(`poly_point_${idx}`, { diameter: 8 }, scene);
      sphere.position.x = (point.x - glassWidth / 2) * scale;
      sphere.position.y = (point.y - glassHeight / 2) * scale;
      sphere.position.z = 10;
      
      const mat = new BABYLON.StandardMaterial(`poly_point_mat_${idx}`, scene);
      mat.diffuseColor = idx === 0 ? new BABYLON.Color3(0.2, 0.8, 0.2) : new BABYLON.Color3(0.2, 0.7, 0.9); // First point green, others teal
      mat.emissiveColor = idx === 0 ? new BABYLON.Color3(0.1, 0.4, 0.1) : new BABYLON.Color3(0.1, 0.35, 0.45);
      sphere.material = mat;
      
      polygonPreviewMeshesRef.current.push(sphere);
    });
    
    // Create lines connecting points
    if (polygonPoints.length >= 2) {
      const linePoints = polygonPoints.map(p => 
        new BABYLON.Vector3(
          (p.x - glassWidth / 2) * scale,
          (p.y - glassHeight / 2) * scale,
          10
        )
      );
      
      const lines = BABYLON.MeshBuilder.CreateLines('poly_preview_lines', { points: linePoints }, scene);
      lines.color = new BABYLON.Color3(0.2, 0.7, 0.9); // Teal color
      polygonPreviewMeshesRef.current.push(lines);
    }
  }, [isDrawingPolygon, polygonPoints, getScale]);

  // Create or update cutout mesh - RECREATE on each update for stability
  const createOrUpdateCutoutMesh = (cutout, scale, scene) => {
    // Always dispose and recreate mesh for clean updates
    const existingMesh = cutoutMeshesRef.current.get(cutout.id);
    if (existingMesh) {
      existingMesh.dispose();
      cutoutMeshesRef.current.delete(cutout.id);
    }
    
    // Calculate position
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    const posX = (cutout.x - glassWidth / 2) * scale;
    const posY = (cutout.y - glassHeight / 2) * scale;
    const rotation = (cutout.rotation || 0) * Math.PI / 180;

    // Create new mesh
    let mesh;
    if (cutout.type === 'HR') {
      // Heart shape - proper heart using CreatePolygon with increased depth
      const size = (cutout.diameter || 60) * scale / 2;
      const heartPoints = [];
      // Create heart shape points
      for (let i = 0; i <= 100; i++) {
        const t = (i / 100) * Math.PI * 2;
        const x = 16 * Math.pow(Math.sin(t), 3) * size / 20;
        const y = -(13 * Math.cos(t) - 5 * Math.cos(2*t) - 2 * Math.cos(3*t) - Math.cos(4*t)) * size / 20;
        heartPoints.push(new BABYLON.Vector3(x, y, 0));
      }
      mesh = BABYLON.MeshBuilder.ExtrudePolygon(`cutout_${cutout.id}`, {
        shape: heartPoints,
        depth: 15,  // Increased depth for better 3D effect
        sideOrientation: BABYLON.Mesh.DOUBLESIDE
      }, scene, earcut);
      mesh.rotation.x = -Math.PI / 2;
    } else if (cutout.type === 'ST') {
      // Star shape - proper 5-pointed star using CreatePolygon with increased depth
      const outerRadius = (cutout.diameter || 70) * scale / 2;
      const innerRadius = outerRadius * 0.38;
      const starPoints = [];
      for (let i = 0; i < 10; i++) {
        const angle = (i * Math.PI / 5) - Math.PI / 2;
        const radius = i % 2 === 0 ? outerRadius : innerRadius;
        starPoints.push(new BABYLON.Vector3(
          Math.cos(angle) * radius,
          Math.sin(angle) * radius,
          0
        ));
      }
      mesh = BABYLON.MeshBuilder.ExtrudePolygon(`cutout_${cutout.id}`, {
        shape: starPoints,
        depth: 15,  // Increased depth for better 3D effect
        sideOrientation: BABYLON.Mesh.DOUBLESIDE
      }, scene, earcut);
      mesh.rotation.x = -Math.PI / 2;
    } else if (cutout.type === 'PT') {
      // Pentagon - 5-sided cylinder with increased height
      mesh = BABYLON.MeshBuilder.CreateCylinder(`cutout_${cutout.id}`, {
        diameter: (cutout.diameter || 60) * scale,
        height: 15,  // Increased height for better 3D effect
        tessellation: 5
      }, scene);
      mesh.rotation.x = Math.PI / 2;
    } else if (cutout.type === 'OC') {
      // Octagon - 8-sided cylinder with increased height
      mesh = BABYLON.MeshBuilder.CreateCylinder(`cutout_${cutout.id}`, {
        diameter: (cutout.diameter || 60) * scale,
        height: 15,  // Increased height for better 3D effect
        tessellation: 8
      }, scene);
      mesh.rotation.x = Math.PI / 2;
    } else if (cutout.type === 'OV') {
      // Oval - scaled sphere with increased height
      const w = (cutout.width || 100) * scale;
      const h = (cutout.height || 60) * scale;
      mesh = BABYLON.MeshBuilder.CreateCylinder(`cutout_${cutout.id}`, {
        diameter: Math.max(w, h),
        height: 15,  // Increased height for better 3D effect
        tessellation: 32
      }, scene);
      mesh.scaling.x = w / Math.max(w, h);
      mesh.scaling.y = h / Math.max(w, h);
      mesh.rotation.x = Math.PI / 2;
    } else if (cutout.type === 'DM') {
      // Diamond - rotated square box with increased depth
      const w = (cutout.width || 70) * scale;
      const h = (cutout.height || 70) * scale;
      mesh = BABYLON.MeshBuilder.CreateBox(`cutout_${cutout.id}`, {
        width: w,
        height: h,
        depth: 15  // Increased depth for better 3D effect
      }, scene);
      mesh.rotation.z = Math.PI / 4; // 45 degree rotation
    } else if (['SH', 'HX'].includes(cutout.type)) {
      const tessellation = cutout.type === 'HX' ? 6 : 32;
      mesh = BABYLON.MeshBuilder.CreateCylinder(`cutout_${cutout.id}`, {
        diameter: (cutout.diameter || 50) * scale,
        height: 15,  // Increased height for better 3D effect
        tessellation
      }, scene);
      mesh.rotation.x = Math.PI / 2;
    } else if (cutout.type === 'T') {
      // Triangle - 3-sided cylinder (reliable) with increased height
      const size = Math.max(cutout.width || 100, cutout.height || 80) * scale;
      mesh = BABYLON.MeshBuilder.CreateCylinder(`cutout_${cutout.id}`, {
        diameter: size,
        height: 15,  // Increased height for better 3D effect
        tessellation: 3
      }, scene);
      mesh.rotation.x = Math.PI / 2;
      mesh.rotation.z = Math.PI / 6; // Rotate to point up
    } else if (cutout.type === 'CN') {
      // Corner Notch - L-shaped cutout with increased depth
      const w = (cutout.width || 80) * scale;
      const h = (cutout.height || 80) * scale;
      const corner = cutout.corner || 'TL';
      
      // Create L-shape based on corner position
      let notchShape;
      if (corner === 'TL') {
        notchShape = [
          new BABYLON.Vector3(0, 0, 0),
          new BABYLON.Vector3(w, 0, 0),
          new BABYLON.Vector3(w, -h, 0),
          new BABYLON.Vector3(0, -h, 0),
        ];
      } else if (corner === 'TR') {
        notchShape = [
          new BABYLON.Vector3(0, 0, 0),
          new BABYLON.Vector3(-w, 0, 0),
          new BABYLON.Vector3(-w, -h, 0),
          new BABYLON.Vector3(0, -h, 0),
        ];
      } else if (corner === 'BL') {
        notchShape = [
          new BABYLON.Vector3(0, 0, 0),
          new BABYLON.Vector3(w, 0, 0),
          new BABYLON.Vector3(w, h, 0),
          new BABYLON.Vector3(0, h, 0),
        ];
      } else { // BR
        notchShape = [
          new BABYLON.Vector3(0, 0, 0),
          new BABYLON.Vector3(-w, 0, 0),
          new BABYLON.Vector3(-w, h, 0),
          new BABYLON.Vector3(0, h, 0),
        ];
      }
      
      mesh = BABYLON.MeshBuilder.ExtrudePolygon(`cutout_${cutout.id}`, { 
        shape: notchShape, 
        depth: 15,  // Increased depth for better 3D effect
        sideOrientation: BABYLON.Mesh.DOUBLESIDE
      }, scene, earcut);
      mesh.rotation.x = -Math.PI / 2;
    } else if (cutout.type === 'PG' && cutout.points && cutout.points.length >= 3) {
      // Custom Polygon with increased depth
      const polygonShape = cutout.points.map(p => 
        new BABYLON.Vector3((p.x - cutout.x) * scale, (p.y - cutout.y) * scale, 0)
      );
      
      mesh = BABYLON.MeshBuilder.ExtrudePolygon(`cutout_${cutout.id}`, { 
        shape: polygonShape, 
        depth: 15,  // Increased depth for better 3D effect
        sideOrientation: BABYLON.Mesh.DOUBLESIDE
      }, scene, earcut);
      mesh.rotation.x = -Math.PI / 2;
    } else {
      mesh = BABYLON.MeshBuilder.CreateBox(`cutout_${cutout.id}`, {
        width: (cutout.width || 100) * scale,
        height: (cutout.height || 80) * scale,
        depth: 15  // Increased depth for better 3D effect
      }, scene);
    }

    mesh.position.x = posX;
    mesh.position.y = posY;
    mesh.position.z = 10;  // Adjusted Z position for increased depth

    mesh.rotation.z = rotation;

    // Get color based on cutout type and view mode
    const cutoutColor = CUTOUT_COLORS[cutout.type] || CUTOUT_COLORS.SH;
    const isSelected = cutout.id === selectedCutoutIdRef.current;
    
    const mat = new BABYLON.StandardMaterial(`cutoutMat_${cutout.id}`, scene);
    
    // Enhanced material properties for better 3D visibility
    mat.wireframe = false;
    mat.specularColor = new BABYLON.Color3(0.3, 0.3, 0.3);  // Increased specularity for 3D effect
    mat.specularPower = 16;  // Glossy finish
    mat.ambientColor = new BABYLON.Color3(0.3, 0.3, 0.3);  // Ambient lighting
    
    // Apply color based on view mode
    if (viewMode === VIEW_MODES.HIGH_CONTRAST) {
      mat.diffuseColor = isSelected ? new BABYLON.Color3(0.5, 0.5, 0.5) : new BABYLON.Color3(0.2, 0.2, 0.2);
      mat.emissiveColor = new BABYLON.Color3(0.1, 0.1, 0.1);
    } else {
      const hexColor = isSelected ? cutoutColor.highlight : cutoutColor.normal;
      mat.diffuseColor = BABYLON.Color3.FromHexString(hexColor);
      mat.emissiveColor = new BABYLON.Color3(0.15, 0.15, 0.15);  // Increased emissive for visibility
    }
    
    mesh.material = mat;
    mesh.isPickable = true;
    mesh.metadata = { cutoutId: cutout.id };

    cutoutMeshesRef.current.set(cutout.id, mesh);
    
    // Add center mark (crosshair) if enabled
    if (showCenterMarks) {
      createCenterMark(cutout, scale, glassWidth, glassHeight, scene);
    }
    
    // Add cutout border/outline
    createCutoutBorder(cutout, scale, glassWidth, glassHeight, scene);
  };

  // Create center mark (crosshair) at cutout center
  const createCenterMark = (cutout, scale, glassWidth, glassHeight, scene) => {
    const posX = (cutout.x - glassWidth / 2) * scale;
    const posY = (cutout.y - glassHeight / 2) * scale;
    const markSize = 8;
    
    // Horizontal line
    const hPoints = [
      new BABYLON.Vector3(posX - markSize, posY, 12),
      new BABYLON.Vector3(posX + markSize, posY, 12)
    ];
    const hLine = BABYLON.MeshBuilder.CreateLines(`centerH_${cutout.id}`, { points: hPoints }, scene);
    hLine.color = viewMode === VIEW_MODES.HIGH_CONTRAST ? new BABYLON.Color3(1, 0, 0) : new BABYLON.Color3(0.8, 0, 0);
    handleMeshesRef.current.push(hLine);
    
    // Vertical line
    const vPoints = [
      new BABYLON.Vector3(posX, posY - markSize, 12),
      new BABYLON.Vector3(posX, posY + markSize, 12)
    ];
    const vLine = BABYLON.MeshBuilder.CreateLines(`centerV_${cutout.id}`, { points: vPoints }, scene);
    vLine.color = viewMode === VIEW_MODES.HIGH_CONTRAST ? new BABYLON.Color3(1, 0, 0) : new BABYLON.Color3(0.8, 0, 0);
    handleMeshesRef.current.push(vLine);
  };

  // Create cutout border/outline
  const createCutoutBorder = (cutout, scale, glassWidth, glassHeight, scene) => {
    const posX = (cutout.x - glassWidth / 2) * scale;
    const posY = (cutout.y - glassHeight / 2) * scale;
    const bounds = getCutoutBounds(cutout);
    
    let borderPoints = [];
    
    // Circular and polygon shapes - use circular border
    if (['SH', 'HX', 'HR', 'ST', 'PT', 'OC'].includes(cutout.type)) {
      const radius = bounds.halfWidth * scale;
      let segments = 32;
      if (cutout.type === 'HX') segments = 6;
      else if (cutout.type === 'PT') segments = 5;
      else if (cutout.type === 'OC') segments = 8;
      else if (cutout.type === 'ST') segments = 10;
      
      for (let i = 0; i <= segments; i++) {
        const angle = (i / segments) * Math.PI * 2;
        borderPoints.push(new BABYLON.Vector3(
          posX + Math.cos(angle) * radius,
          posY + Math.sin(angle) * radius,
          12
        ));
      }
    } else {
      // Rectangle border (including oval, diamond, rectangle, triangle)
      const halfW = bounds.halfWidth * scale;
      const halfH = bounds.halfHeight * scale;
      borderPoints = [
        new BABYLON.Vector3(posX - halfW, posY - halfH, 12),
        new BABYLON.Vector3(posX + halfW, posY - halfH, 12),
        new BABYLON.Vector3(posX + halfW, posY + halfH, 12),
        new BABYLON.Vector3(posX - halfW, posY + halfH, 12),
        new BABYLON.Vector3(posX - halfW, posY - halfH, 12),
      ];
    }
    
    const border = BABYLON.MeshBuilder.CreateLines(`border_${cutout.id}`, { 
      points: borderPoints,
      updatable: true
    }, scene);
    
    // Make borders thicker and more visible
    border.color = viewMode === VIEW_MODES.HIGH_CONTRAST 
      ? new BABYLON.Color3(0, 0, 0) 
      : BABYLON.Color3.FromHexString(CUTOUT_COLORS[cutout.type]?.normal || '#FF0000');
    
    // Increase line width for better visibility (WebGL limitation: max ~8, fallback to ribbons for thicker)
    border.enableEdgesRendering();
    border.edgesWidth = 8.0;
    border.edgesColor = viewMode === VIEW_MODES.HIGH_CONTRAST 
      ? new BABYLON.Color4(0, 0, 0, 1) 
      : BABYLON.Color4.FromHexString(CUTOUT_COLORS[cutout.type]?.normal || '#FF0000FF');
    
    handleMeshesRef.current.push(border);
  };

  // Create or update cutout labels - ATTACHED to cutout position
  const createOrUpdateCutoutLabels = (cutout, scale, gui, cutoutIndex) => {
    // Remove existing labels for this cutout
    const existingLabels = cutoutLabelsRef.current.get(cutout.id);
    if (existingLabels) {
      existingLabels.forEach(l => l.dispose());
    }

    const labels = [];
    const shapeConfig = CUTOUT_SHAPES.find(s => s.id === cutout.type);
    
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    const posX = (cutout.x - glassWidth / 2) * scale;
    const posY = (cutout.y - glassHeight / 2) * scale;
    
    const textColor = viewMode === VIEW_MODES.HIGH_CONTRAST ? '#000000' : '#1a1a1a';
    const dimColor = viewMode === VIEW_MODES.HIGH_CONTRAST ? '#000000' : '#dc2626';

    // Cutout number label (e.g., H1, R1, T1)
    if (showCutoutNumbers) {
      const numberLabel = new TextBlock(`number_${cutout.id}`);
      numberLabel.text = `${shapeConfig?.label || 'C'}${cutoutIndex + 1}`;
      numberLabel.color = viewMode === VIEW_MODES.HIGH_CONTRAST ? '#ffffff' : '#ffffff';
      numberLabel.fontSize = 11;
      numberLabel.fontWeight = 'bold';
      numberLabel.outlineWidth = 2;
      numberLabel.outlineColor = CUTOUT_COLORS[cutout.type]?.normal || '#3B82F6';
      numberLabel.left = `${posX}px`;
      numberLabel.top = `${-posY - 5}px`;
      gui.addControl(numberLabel);
      labels.push(numberLabel);
    }
    
    // Delete button - ALWAYS VISIBLE on each cutout
    const bounds = getCutoutBounds(cutout);
    const deleteBtn = BabylonButton.CreateSimpleButton(`delete_${cutout.id}`, "✕");
    deleteBtn.width = "24px";
    deleteBtn.height = "24px";
    deleteBtn.color = "#ffffff";
    deleteBtn.background = "#ef4444";
    deleteBtn.fontSize = 14;
    deleteBtn.fontWeight = "bold";
    deleteBtn.thickness = 2;
    deleteBtn.cornerRadius = 12;
    deleteBtn.left = `${posX + bounds.halfWidth * scale + 15}px`;
    deleteBtn.top = `${-posY - bounds.halfHeight * scale - 15}px`;
    deleteBtn.hoverCursor = "pointer";
    deleteBtn.onPointerClickObservable.add(() => {
      removeCutout(cutout.id);
    });
    gui.addControl(deleteBtn);
    labels.push(deleteBtn);

    // Inner dimension label - DIRECTLY attached to shape position
    const innerLabel = new TextBlock(`inner_${cutout.id}`);
    if (['SH', 'HX', 'HR', 'ST', 'PT', 'OC'].includes(cutout.type)) {
      innerLabel.text = `Ø${Math.round(cutout.diameter || 60)}`;
    } else if (cutout.type === 'DM') {
      innerLabel.text = `${Math.round(cutout.width || 70)}×${Math.round(cutout.width || 70)}`;
    } else {
      innerLabel.text = `${Math.round(cutout.width || 100)}×${Math.round(cutout.height || 80)}`;
    }
    innerLabel.color = textColor;
    innerLabel.fontSize = 9;
    innerLabel.fontWeight = 'bold';
    innerLabel.left = `${posX}px`;
    innerLabel.top = `${-posY + 8}px`;
    gui.addControl(innerLabel);
    labels.push(innerLabel);

    // Edge distance calculations (reuse bounds from delete button above)
    const leftDist = Math.round(cutout.x - bounds.halfWidth);
    const rightDist = Math.round(glassWidth - cutout.x - bounds.halfWidth);
    const topDist = Math.round(glassHeight - cutout.y - bounds.halfHeight);
    const bottomDist = Math.round(cutout.y - bounds.halfHeight);

    // Distance labels with dimension lines
    if (showDimensionLines) {
      const labelOffset = 30;
      
      // Left dimension
      const leftLabel = new TextBlock(`left_${cutout.id}`);
      leftLabel.text = `←${leftDist}mm`;
      leftLabel.color = dimColor;
      leftLabel.fontSize = 8;
      leftLabel.left = `${posX - bounds.halfWidth * scale - labelOffset}px`;
      leftLabel.top = `${-posY}px`;
      gui.addControl(leftLabel);
      labels.push(leftLabel);

      // Right dimension
      const rightLabel = new TextBlock(`right_${cutout.id}`);
      rightLabel.text = `${rightDist}mm→`;
      rightLabel.color = dimColor;
      rightLabel.fontSize = 8;
      rightLabel.left = `${posX + bounds.halfWidth * scale + labelOffset}px`;
      rightLabel.top = `${-posY}px`;
      gui.addControl(rightLabel);
      labels.push(rightLabel);

      // Top dimension
      const topLabel = new TextBlock(`top_${cutout.id}`);
      topLabel.text = `↑${topDist}mm`;
      topLabel.color = dimColor;
      topLabel.fontSize = 8;
      topLabel.left = `${posX}px`;
      topLabel.top = `${-posY - bounds.halfHeight * scale - 18}px`;
      gui.addControl(topLabel);
      labels.push(topLabel);

      // Bottom dimension
      const bottomLabel = new TextBlock(`bottom_${cutout.id}`);
      bottomLabel.text = `↓${bottomDist}mm`;
      bottomLabel.color = dimColor;
      bottomLabel.fontSize = 8;
      bottomLabel.left = `${posX}px`;
      bottomLabel.top = `${-posY + bounds.halfHeight * scale + 18}px`;
      gui.addControl(bottomLabel);
      labels.push(bottomLabel);
    }

    cutoutLabelsRef.current.set(cutout.id, labels);
  };

  // Update ONLY edge distance labels in real-time (called during drag/resize)
  const updateEdgeDistanceLabels = (cutoutId) => {
    const currentItem = glassItems[activeItemIndexRef.current];
    if (!currentItem) return;
    
    const cutout = currentItem.cutouts.find(c => c.id === cutoutId);
    if (!cutout) return;
    
    const existingLabels = cutoutLabelsRef.current.get(cutoutId);
    if (!existingLabels || !showDimensionLines) return;
    
    const glassWidth = currentItem.width_mm;
    const glassHeight = currentItem.height_mm;
    const bounds = getCutoutBounds(cutout);
    const scale = getScale();
    
    const leftDist = Math.round(cutout.x - bounds.halfWidth);
    const rightDist = Math.round(glassWidth - cutout.x - bounds.halfWidth);
    const topDist = Math.round(glassHeight - cutout.y - bounds.halfHeight);
    const bottomDist = Math.round(cutout.y - bounds.halfHeight);
    
    const posX = (cutout.x - glassWidth / 2) * scale;
    const posY = (cutout.y - glassHeight / 2) * scale;
    const labelOffset = 30;
    
    // Update existing labels - find by ID pattern
    existingLabels.forEach(label => {
      if (label.name?.startsWith('left_')) {
        label.text = `←${leftDist}mm`;
        label.left = `${posX - bounds.halfWidth * scale - labelOffset}px`;
        label.top = `${-posY}px`;
      } else if (label.name?.startsWith('right_')) {
        label.text = `${rightDist}mm→`;
        label.left = `${posX + bounds.halfWidth * scale + labelOffset}px`;
        label.top = `${-posY}px`;
      } else if (label.name?.startsWith('top_')) {
        label.text = `↑${topDist}mm`;
        label.left = `${posX}px`;
        label.top = `${-posY - bounds.halfHeight * scale - 18}px`;
      } else if (label.name?.startsWith('bottom_')) {
        label.text = `↓${bottomDist}mm`;
        label.left = `${posX}px`;
        label.top = `${-posY + bounds.halfHeight * scale + 18}px`;
      } else if (label.name?.startsWith('inner_')) {
        // Update inner dimension label position
        label.left = `${posX}px`;
        label.top = `${-posY + 8}px`;
        if (['SH', 'HX', 'HR'].includes(cutout.type)) {
          label.text = `Ø${Math.round(cutout.diameter || 50)}`;
        } else {
          label.text = `${Math.round(cutout.width || 100)}×${Math.round(cutout.height || 80)}`;
        }
      } else if (label.name?.startsWith('number_')) {
        // Update number label position
        label.left = `${posX}px`;
        label.top = `${-posY - 5}px`;
      }
    });
  };

  // Create grid overlay on glass
  const createGridOverlay = (scale, scene) => {
    // Clear previous grid
    gridLinesRef.current.forEach(line => line.dispose());
    gridLinesRef.current = [];
    
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    const gridStep = snapGridSize; // Use snap grid size
    
    const halfW = (glassWidth * scale) / 2;
    const halfH = (glassHeight * scale) / 2;
    
    const gridColor = viewMode === VIEW_MODES.HIGH_CONTRAST 
      ? new BABYLON.Color3(0.5, 0.5, 0.5) 
      : new BABYLON.Color3(0.7, 0.8, 0.9);
    
    // Vertical lines
    for (let x = 0; x <= glassWidth; x += gridStep) {
      const posX = (x - glassWidth / 2) * scale;
      const points = [
        new BABYLON.Vector3(posX, -halfH, 6),
        new BABYLON.Vector3(posX, halfH, 6)
      ];
      const line = BABYLON.MeshBuilder.CreateLines(`gridV_${x}`, { points }, scene);
      line.color = gridColor;
      line.alpha = 0.5;
      gridLinesRef.current.push(line);
    }
    
    // Horizontal lines
    for (let y = 0; y <= glassHeight; y += gridStep) {
      const posY = (y - glassHeight / 2) * scale;
      const points = [
        new BABYLON.Vector3(-halfW, posY, 6),
        new BABYLON.Vector3(halfW, posY, 6)
      ];
      const line = BABYLON.MeshBuilder.CreateLines(`gridH_${y}`, { points }, scene);
      line.color = gridColor;
      line.alpha = 0.5;
      gridLinesRef.current.push(line);
    }
  };

  // Export 3D model (STL/OBJ)
  const [exporting3D, setExporting3D] = useState(false);
  
  const export3DModel = async (format = 'stl') => {
    setExporting3D(true);
    try {
      // Validate glass dimensions
      if (!config.width_mm || !config.height_mm || config.width_mm <= 0 || config.height_mm <= 0) {
        toast.error('Please set valid glass dimensions');
        setExporting3D(false);
        return;
      }

      // Convert cutouts to API format
      const cutoutsData = config.cutouts.map(c => {
        const cutout = {
          shape: c.type === 'SH' ? 'circle' : 
                 c.type === 'R' ? 'rectangle' : 
                 c.type === 'T' ? 'triangle' :
                 c.type === 'HX' ? 'hexagon' :
                 c.type === 'HR' ? 'heart' : 'circle',
          x: Math.round(c.x || 0),
          y: Math.round(c.y || 0)
        };
        
        if (c.diameter) {
          cutout.diameter = Math.round(c.diameter);
        } else if (c.width) {
          cutout.width = Math.round(c.width);
          cutout.height = Math.round(c.height || c.width);
        }
        
        return cutout;
      });

      const response = await fetch(`${API_URL}/glass-3d/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          width: config.width_mm,
          height: config.height_mm,
          thickness: config.thickness_mm || 8,
          cutouts: cutoutsData,
          export_format: format
        })
      });
      
      if (response.ok) {
        const data = await response.json();
        
        // Decode base64 file data
        const binaryString = atob(data.file_data);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
          bytes[i] = binaryString.charCodeAt(i);
        }
        const blob = new Blob([bytes], { 
          type: format === 'stl' ? 'model/stl' : 
                format === 'obj' ? 'model/obj' : 
                'application/json' 
        });
        
        // Download file
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `glass_${config.width_mm}x${config.height_mm}_${Date.now()}.${format}`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
        
        toast.success(`${format.toUpperCase()} model exported successfully! (${(data.volume_mm3 / 1000000).toFixed(2)}L, ${data.weight_kg.toFixed(2)}kg)`);
      } else {
        const errorData = await response.json().catch(() => ({ detail: 'Unknown error' }));
        console.error('3D export error:', errorData);
        toast.error(`Failed to export 3D model: ${errorData.detail || response.statusText}`);
      }
    } catch (error) {
      console.error('3D export failed:', error);
      toast.error(`Error exporting 3D model: ${error.message || 'Network error'}`);
    } finally {
      setExporting3D(false);
    }
  };

  // Export specification sheet as PDF
  const exportToPDF = async () => {
    setExportingPDF(true);
    try {
      // Validate glass dimensions
      if (!config.width_mm || !config.height_mm || config.width_mm <= 0 || config.height_mm <= 0) {
        toast.error('Please set valid glass dimensions');
        setExportingPDF(false);
        return;
      }

      const token = localStorage.getItem('token');
      const cutoutsData = config.cutouts.map((c, idx) => {
        const shapeConfig = CUTOUT_SHAPES.find(s => s.id === c.type);
        const halfSize = c.diameter ? c.diameter/2 : (c.width || 0)/2;
        const halfHeight = c.height ? c.height/2 : halfSize;
        
        return {
          number: `${shapeConfig?.label || 'C'}${idx + 1}`,
          type: shapeConfig?.name || 'Unknown',
          diameter: c.diameter || undefined,
          width: c.width || undefined,
          height: c.height || undefined,
          x: Math.round(c.x || 0),
          y: Math.round(c.y || 0),
          rotation: Math.round(c.rotation || 0),
          left_edge: Math.max(0, Math.round((c.x || 0) - halfSize)),
          right_edge: Math.max(0, Math.round(config.width_mm - (c.x || 0) - halfSize)),
          top_edge: Math.max(0, Math.round(config.height_mm - (c.y || 0) - halfHeight)),
          bottom_edge: Math.max(0, Math.round((c.y || 0) - halfHeight)),
        };
      });

      const response = await fetch(`${API_URL}/erp/glass-config/export-pdf`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          glass_config: {
            width_mm: config.width_mm,
            height_mm: config.height_mm,
            thickness_mm: config.thickness_mm || 8,
            glass_type: config.glass_type || 'Clear',
            color_name: config.color_name || 'Clear',
            application: config.application || 'General',
          },
          cutouts: cutoutsData,
          quantity: config.quantity || 1,
        })
      });
      
      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `glass_specification_${Date.now()}.pdf`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
        toast.success('PDF exported successfully!');
      } else {
        const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
        console.error('PDF export error:', errorData);
        toast.error(`Failed to export PDF: ${errorData.error || response.statusText}`);
      }
    } catch (error) {
      console.error('PDF export failed:', error);
      toast.error(`Error exporting PDF: ${error.message || 'Network error'}`);
    } finally {
      setExportingPDF(false);
    }
  };

  // Create shareable link
  const createShareLink = async () => {
    setCreatingShareLink(true);
    try {
      const response = await fetch(`${API_URL}/erp/glass-config/share`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          glass_config: {
            width_mm: config.width_mm,
            height_mm: config.height_mm,
            thickness_mm: config.thickness_mm,
            glass_type: config.glass_type,
            color_name: config.color_name,
            application: config.application,
          },
          cutouts: config.cutouts.map(c => ({
            type: c.type,
            diameter: c.diameter,
            width: c.width,
            height: c.height,
            x: c.x,
            y: c.y,
            rotation: c.rotation || 0,
          })),
          title: `Custom Glass ${config.width_mm}×${config.height_mm}mm`
        })
      });
      
      if (response.ok) {
        const data = await response.json();
        const fullUrl = `${window.location.origin}/share/${data.share_id}`;
        setShareUrl(fullUrl);
        setShowShareModal(true);
        toast.success('Share link created!');
      } else {
        toast.error('Failed to create share link');
      }
    } catch (error) {
      console.error('Share link creation failed:', error);
      toast.error('Error creating share link');
    } finally {
      setCreatingShareLink(false);
    }
  };

  // Share helpers
  const copyShareLink = () => {
    navigator.clipboard.writeText(shareUrl);
    toast.success('Link copied to clipboard!');
  };

  const shareViaWhatsApp = () => {
    const text = `Check out my custom glass configuration (${config.width_mm}×${config.height_mm}mm):`;
    window.open(`https://wa.me/?text=${encodeURIComponent(text)}%20${encodeURIComponent(shareUrl)}`, '_blank');
  };

  const shareViaEmail = () => {
    const subject = encodeURIComponent(`My Custom Glass Configuration - ${config.width_mm}×${config.height_mm}mm`);
    const body = encodeURIComponent(`Hi,\n\nI've created a custom glass configuration and wanted to share it with you:\n\n${shareUrl}\n\nTake a look and let me know what you think!`);
    window.open(`mailto:?subject=${subject}&body=${body}`, '_blank');
  };

  // Add to Order workflow - Send ALL glass items
  const handleAddToOrder = async () => {
    // Validation - check if ANY glass item has cutouts
    const hasValidItems = glassItems.some(item => 
      item.cutouts.length > 0 && item.width_mm && item.height_mm && item.thickness_mm
    );
    
    if (!hasValidItems) {
      toast.error('Please add at least one glass with cutouts before creating order');
      return;
    }
    
    setAddingToOrder(true);
    try {
      // Calculate total quantity and cutouts
      const totalQuantity = glassItems.reduce((sum, item) => sum + (item.quantity || 1), 0);
      const totalCutouts = glassItems.reduce((sum, item) => sum + item.cutouts.length, 0);
      
      // Prepare ALL glass items for order
      const glassConfigs = glassItems
        .filter(item => item.cutouts.length > 0)
        .map((item, idx) => ({
          item_number: idx + 1,
          width_mm: item.width_mm,
          height_mm: item.height_mm,
          thickness_mm: item.thickness_mm,
          glass_type: item.glass_type,
          color_name: item.color_name,
          application: item.application,
          quantity: item.quantity || 1,
          cutouts: item.cutouts.map(c => ({
            id: c.id,
            type: c.type,
            diameter: c.diameter,
            width: c.width,
            height: c.height,
            x: c.x,
            y: c.y,
            rotation: c.rotation || 0,
          }))
        }));
      
      // Save design with order
      const response = await fetch(`${API_URL}/orders/with-design`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({
          order_data: {
            customer_name: user?.name || 'Guest',
            customer_email: user?.email,
            customer_phone: user?.phone || '',
            quantity: totalQuantity,
            notes: `Custom 3D Glass Design - ${glassConfigs.length} glass items, ${totalCutouts} total cutouts`,
            status: 'pending'
          },
          glass_configs: glassConfigs,
          // Also send first item as glass_config for backward compatibility
          glass_config: glassConfigs[0]
        })
      });
      
      if (response.ok) {
        const data = await response.json();
        toast.success(`Order created with ${glassConfigs.length} glass item(s)!`);
        setTimeout(() => navigate('/portal'), 1500);
      } else {
        const error = await response.json();
        toast.error(error.detail || 'Failed to create order');
      }
    } catch (error) {
      console.error('Order creation failed:', error);
      toast.error('Error creating order. Please try again.');
    } finally {
      setAddingToOrder(false);
    }
  };

  // Generate Quotation - for ALL glass items
  const handleGenerateQuotation = () => {
    // Validation
    const hasValidItems = glassItems.some(item => 
      item.cutouts.length > 0 && item.width_mm && item.height_mm
    );
    
    if (!hasValidItems) {
      toast.error('Please add at least one glass with cutouts to generate quotation');
      return;
    }
    
    // Build detailed quotation for all items
    const prices = calculateLivePrice();
    let quotationText = `📋 QUOTATION - ${prices.itemsBreakdown.length} Glass Item(s)\n\n`;
    
    prices.itemsBreakdown.forEach((item) => {
      const glassItem = glassItems[item.index - 1];
      quotationText += `🔷 Glass #${item.index}:\n`;
      quotationText += `   ${glassItem.width_mm}mm × ${glassItem.height_mm}mm (${item.area_sqft.toFixed(2)} sq ft)\n`;
      quotationText += `   ${glassItem.glass_type} - ${glassItem.thickness_mm}mm\n`;
      quotationText += `   Cutouts: ${glassItem.cutouts.length} × ₹${pricingRules?.cutout_price ?? 50} = ₹${item.cutoutCharge}\n`;
      quotationText += `   Qty: ${item.quantity} × ₹${(item.itemTotal / item.quantity).toFixed(2)} = ₹${item.itemTotal.toFixed(2)}\n\n`;
    });
    
    quotationText += `━━━━━━━━━━━━━━━━━━━━━━\n`;
    quotationText += `💵 GRAND TOTAL: ₹${prices.grandTotal.toFixed(2)}\n`;
    quotationText += `💳 Advance (50%): ₹${prices.advanceAmount.toFixed(2)}`;
    
    toast.success(quotationText, { duration: 15000 });
  };

  // 3D View rotation functions
  const rotate3DView = (direction) => {
    if (!cameraRef.current) return;
    const cam = cameraRef.current;
    
    switch(direction) {
      case 'front':
        cam.alpha = -Math.PI / 2;
        cam.beta = Math.PI / 2;
        break;
      case 'top':
        cam.alpha = -Math.PI / 2;
        cam.beta = 0.1;
        break;
      case 'side':
        cam.alpha = 0;
        cam.beta = Math.PI / 2;
        break;
      case 'angle':
        cam.alpha = -Math.PI / 4;
        cam.beta = Math.PI / 3;
        break;
      case 'left':
        cam.alpha += 0.2;
        break;
      case 'right':
        cam.alpha -= 0.2;
        break;
      case 'up':
        cam.beta = Math.max(0.1, cam.beta - 0.2);
        break;
      case 'down':
        cam.beta = Math.min(Math.PI - 0.1, cam.beta + 0.2);
        break;
    }
    setViewAngle({ alpha: cam.alpha, beta: cam.beta });
  };

  // Place corner notch at specific corner
  const placeCornerNotch = (corner) => {
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    const defaultSize = 80;
    
    let x, y;
    switch(corner) {
      case 'TL':
        x = defaultSize / 2;
        y = glassHeight - defaultSize / 2;
        break;
      case 'TR':
        x = glassWidth - defaultSize / 2;
        y = glassHeight - defaultSize / 2;
        break;
      case 'BL':
        x = defaultSize / 2;
        y = defaultSize / 2;
        break;
      case 'BR':
        x = glassWidth - defaultSize / 2;
        y = defaultSize / 2;
        break;
      default:
        x = glassWidth / 2;
        y = glassHeight / 2;
    }
    
    const newCutout = {
      id: `cutout_${Date.now()}`,
      type: 'CN',
      x,
      y,
      width: defaultSize,
      height: defaultSize,
      corner: corner,
      rotation: 0,
    };
    
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      return { ...item, cutouts: [...item.cutouts, newCutout] };
    }));
    
    setSelectedCutoutId(newCutout.id);
    selectedCutoutIdRef.current = newCutout.id;
    setIsPlacementMode(false);
    isPlacementModeRef.current = false;
    toast.success(`Corner notch placed at ${corner}!`);
  };

  // Handle polygon drawing click
  const handlePolygonDrawClick = (clickX, clickY) => {
    const newPoint = { x: clickX, y: clickY };
    const currentPoints = [...polygonPointsRef.current, newPoint];
    setPolygonPoints(currentPoints);
    
    // Check if close to first point to complete polygon
    if (currentPoints.length >= 3) {
      const firstPoint = currentPoints[0];
      const distance = Math.sqrt(Math.pow(clickX - firstPoint.x, 2) + Math.pow(clickY - firstPoint.y, 2));
      
      if (distance < 20) {
        // Complete the polygon
        completePolygon(currentPoints.slice(0, -1)); // Remove the last point (closing click)
      }
    }
  };

  // Complete polygon and create cutout
  const completePolygon = (points) => {
    if (points.length < 3) {
      toast.error('Polygon needs at least 3 points');
      setPolygonPoints([]);
      setIsDrawingPolygon(false);
      isDrawingPolygonRef.current = false;
      return;
    }
    
    // Calculate center point
    const centerX = points.reduce((sum, p) => sum + p.x, 0) / points.length;
    const centerY = points.reduce((sum, p) => sum + p.y, 0) / points.length;
    
    const newCutout = {
      id: `cutout_${Date.now()}`,
      type: 'PG',
      x: centerX,
      y: centerY,
      points: points,
      rotation: 0,
    };
    
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      return { ...item, cutouts: [...item.cutouts, newCutout] };
    }));
    
    setSelectedCutoutId(newCutout.id);
    selectedCutoutIdRef.current = newCutout.id;
    setPolygonPoints([]);
    setIsDrawingPolygon(false);
    isDrawingPolygonRef.current = false;
    toast.success('Custom polygon created!');
  };

  // Cancel polygon drawing
  const cancelPolygonDrawing = () => {
    setPolygonPoints([]);
    setIsDrawingPolygon(false);
    isDrawingPolygonRef.current = false;
    toast.info('Polygon drawing cancelled');
  };

  // ============== MEASUREMENT TOOL ==============
  
  // Handle measurement click
  const handleMeasurementClick = (clickX, clickY) => {
    if (currentMeasurePointRef.current === null) {
      // First point
      setCurrentMeasurePoint({ x: clickX, y: clickY });
      toast.info('Click second point to complete measurement');
    } else {
      // Second point - complete measurement
      const pointA = currentMeasurePointRef.current;
      const pointB = { x: clickX, y: clickY };
      const distance = Math.sqrt(
        Math.pow(pointB.x - pointA.x, 2) + Math.pow(pointB.y - pointA.y, 2)
      );
      
      const newMeasurement = {
        id: `measure_${Date.now()}`,
        pointA,
        pointB,
        distance: Math.round(distance * 10) / 10 // Round to 1 decimal
      };
      
      setMeasurePoints(prev => [...prev, newMeasurement]);
      setCurrentMeasurePoint(null);
      toast.success(`Distance: ${newMeasurement.distance} mm`);
    }
  };
  
  // Draw measurement lines on canvas
  const drawMeasurementLines = useCallback(() => {
    const scene = sceneRef.current;
    const gui = guiTextureRef.current;
    if (!scene || !gui) return;
    
    // Clear existing measurement visuals
    measurementLinesRef.current.forEach(item => {
      if (item.dispose) item.dispose();
    });
    measurementLinesRef.current = [];
    
    const scale = getScale();
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    
    // Draw current point if measuring
    if (currentMeasurePoint) {
      const px = (currentMeasurePoint.x - glassWidth / 2) * scale;
      const py = (currentMeasurePoint.y - glassHeight / 2) * scale;
      
      const marker = BABYLON.MeshBuilder.CreateSphere('measureMarker', { diameter: 8 }, scene);
      marker.position.x = px;
      marker.position.y = py;
      marker.position.z = 15;
      
      const markerMat = new BABYLON.StandardMaterial('markerMat', scene);
      markerMat.diffuseColor = new BABYLON.Color3(1, 0.6, 0);
      markerMat.emissiveColor = new BABYLON.Color3(0.5, 0.3, 0);
      marker.material = markerMat;
      measurementLinesRef.current.push(marker);
    }
    
    // Draw completed measurements
    measurePoints.forEach((measurement, idx) => {
      const ax = (measurement.pointA.x - glassWidth / 2) * scale;
      const ay = (measurement.pointA.y - glassHeight / 2) * scale;
      const bx = (measurement.pointB.x - glassWidth / 2) * scale;
      const by = (measurement.pointB.y - glassHeight / 2) * scale;
      
      // Point A marker
      const markerA = BABYLON.MeshBuilder.CreateSphere(`measureA_${idx}`, { diameter: 6 }, scene);
      markerA.position.set(ax, ay, 15);
      const matA = new BABYLON.StandardMaterial(`matA_${idx}`, scene);
      matA.diffuseColor = new BABYLON.Color3(1, 0.5, 0);
      matA.emissiveColor = new BABYLON.Color3(0.5, 0.25, 0);
      markerA.material = matA;
      measurementLinesRef.current.push(markerA);
      
      // Point B marker
      const markerB = BABYLON.MeshBuilder.CreateSphere(`measureB_${idx}`, { diameter: 6 }, scene);
      markerB.position.set(bx, by, 15);
      markerB.material = matA;
      measurementLinesRef.current.push(markerB);
      
      // Dashed line between points
      const linePoints = [
        new BABYLON.Vector3(ax, ay, 15),
        new BABYLON.Vector3(bx, by, 15)
      ];
      const line = BABYLON.MeshBuilder.CreateLines(`measureLine_${idx}`, { points: linePoints }, scene);
      line.color = new BABYLON.Color3(1, 0.6, 0);
      measurementLinesRef.current.push(line);
      
      // Distance label at midpoint
      const midX = (ax + bx) / 2;
      const midY = (ay + by) / 2;
      
      const distLabel = new TextBlock(`distLabel_${idx}`);
      distLabel.text = `${measurement.distance} mm`;
      distLabel.color = '#FF9500';
      distLabel.fontSize = 12;
      distLabel.fontWeight = 'bold';
      distLabel.outlineWidth = 2;
      distLabel.outlineColor = 'white';
      distLabel.left = `${midX}px`;
      distLabel.top = `${-midY - 12}px`;
      gui.addControl(distLabel);
      measurementLinesRef.current.push(distLabel);
    });
  }, [measurePoints, currentMeasurePoint, getScale]);
  
  // Update measurements when they change
  useEffect(() => {
    if (sceneRef.current) {
      drawMeasurementLines();
    }
  }, [measurePoints, currentMeasurePoint, drawMeasurementLines]);
  
  // Clear all measurements
  const clearMeasurements = () => {
    setMeasurePoints([]);
    setCurrentMeasurePoint(null);
    measurementLinesRef.current.forEach(item => {
      if (item.dispose) item.dispose();
    });
    measurementLinesRef.current = [];
    toast.info('Measurements cleared');
  };
  
  // Toggle measurement mode
  const toggleMeasurementMode = () => {
    if (isMeasuring) {
      setIsMeasuring(false);
      isMeasuringRef.current = false;
      setCurrentMeasurePoint(null);
    } else {
      setIsMeasuring(true);
      isMeasuringRef.current = true;
      setIsPlacementMode(false);
      isPlacementModeRef.current = false;
      setIsDrawingPolygon(false);
      isDrawingPolygonRef.current = false;
      setSelectedCutoutId(null);
      toast.info('Click two points to measure distance');
    }
  };

  // ============== AUTO-ALIGN TO CENTER ==============
  
  // Auto-align selected cutout to center lines
  const autoAlignCutout = (alignment) => {
    if (!selectedCutoutId) {
      toast.error('Select a cutout first');
      return;
    }
    
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      
      return {
        ...item,
        cutouts: item.cutouts.map(c => {
          if (c.id !== selectedCutoutId) return c;
          
          let newX = c.x;
          let newY = c.y;
          
          switch(alignment) {
            case 'centerH': // Horizontal center
              newX = glassWidth / 2;
              break;
            case 'centerV': // Vertical center
              newY = glassHeight / 2;
              break;
            case 'center': // Both center
              newX = glassWidth / 2;
              newY = glassHeight / 2;
              break;
            case 'left':
              newX = getCutoutBounds(c).halfWidth + 10;
              break;
            case 'right':
              newX = glassWidth - getCutoutBounds(c).halfWidth - 10;
              break;
            case 'top':
              newY = glassHeight - getCutoutBounds(c).halfHeight - 10;
              break;
            case 'bottom':
              newY = getCutoutBounds(c).halfHeight + 10;
              break;
          }
          
          return { ...c, x: newX, y: newY };
        })
      };
    }));
    
    toast.success(`Aligned to ${alignment}`);
  };

  // ============== DOOR FITTINGS ==============
  
  // Place door fitting at predefined position
  const placeDoorFitting = (fitting) => {
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    
    const x = glassWidth * fitting.position.xPercent;
    const y = glassHeight * fitting.position.yPercent;
    
    const newCutout = {
      id: `cutout_${Date.now()}`,
      type: fitting.type,
      x,
      y,
      diameter: fitting.diameter,
      width: fitting.width,
      height: fitting.height,
      rotation: 0,
      label: fitting.name,
    };
    
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      return { ...item, cutouts: [...item.cutouts, newCutout] };
    }));
    
    setSelectedCutoutId(newCutout.id);
    selectedCutoutIdRef.current = newCutout.id;
    toast.success(`${fitting.name} placed!`);
  };
  
  // ============== QUICK DOOR SETUP ==============
  // One-click to add all standard door fittings
  const quickDoorSetup = () => {
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    
    // Standard door fittings configuration
    const doorFittings = [
      // Handle - Center right
      { type: 'SH', diameter: 35, xPercent: 0.88, yPercent: 0.5, label: 'Handle' },
      // Top Hinge
      { type: 'R', width: 80, height: 25, xPercent: 0.08, yPercent: 0.92, label: 'Hinge Top' },
      // Middle Hinge
      { type: 'R', width: 80, height: 25, xPercent: 0.08, yPercent: 0.5, label: 'Hinge Mid' },
      // Bottom Hinge
      { type: 'R', width: 80, height: 25, xPercent: 0.08, yPercent: 0.08, label: 'Hinge Bot' },
      // Lock
      { type: 'R', width: 25, height: 120, xPercent: 0.12, yPercent: 0.5, label: 'Lock' },
    ];
    
    const newCutouts = doorFittings.map((fitting, idx) => ({
      id: `cutout_door_${Date.now()}_${idx}`,
      type: fitting.type,
      x: glassWidth * fitting.xPercent,
      y: glassHeight * fitting.yPercent,
      diameter: fitting.diameter,
      width: fitting.width,
      height: fitting.height,
      rotation: 0,
      label: fitting.label,
    }));
    
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      return { ...item, cutouts: [...item.cutouts, ...newCutouts] };
    }));
    
    toast.success(`🚪 Door Setup Complete! Added ${doorFittings.length} fittings`);
  };

  // Create resize and rotation handles
  const createHandles = (cutout, scale, scene) => {
    const bounds = getCutoutBounds(cutout);
    const halfW = bounds.halfWidth * scale;
    const halfH = bounds.halfHeight * scale;
    
    const glassWidth = configRef.current.width_mm;
    const glassHeight = configRef.current.height_mm;
    const cx = (cutout.x - glassWidth / 2) * scale;
    const cy = (cutout.y - glassHeight / 2) * scale;

    // 8 resize handles
    const handlePositions = [
      { pos: 'tl', x: cx - halfW, y: cy + halfH },
      { pos: 'tr', x: cx + halfW, y: cy + halfH },
      { pos: 'bl', x: cx - halfW, y: cy - halfH },
      { pos: 'br', x: cx + halfW, y: cy - halfH },
      { pos: 'tm', x: cx, y: cy + halfH },
      { pos: 'bm', x: cx, y: cy - halfH },
      { pos: 'lm', x: cx - halfW, y: cy },
      { pos: 'rm', x: cx + halfW, y: cy },
    ];

    handlePositions.forEach(hp => {
      const handle = BABYLON.MeshBuilder.CreateSphere(`handle_${hp.pos}`, { diameter: 8 }, scene);
      handle.position.x = hp.x;
      handle.position.y = hp.y;
      handle.position.z = 12;

      const mat = new BABYLON.StandardMaterial(`handleMat_${hp.pos}`, scene);
      mat.diffuseColor = new BABYLON.Color3(0.2, 0.5, 1);
      mat.emissiveColor = new BABYLON.Color3(0.1, 0.25, 0.5);
      handle.material = mat;
      handle.isPickable = true;
      handle.metadata = { handleType: 'resize', position: hp.pos, cutoutId: cutout.id };

      handleMeshesRef.current.push(handle);
    });

    // Rotation handle (green, above shape)
    const rotHandle = BABYLON.MeshBuilder.CreateSphere('rotHandle', { diameter: 10 }, scene);
    rotHandle.position.x = cx;
    rotHandle.position.y = cy + halfH + 20;
    rotHandle.position.z = 12;

    const rotMat = new BABYLON.StandardMaterial('rotMat', scene);
    rotMat.diffuseColor = new BABYLON.Color3(0.2, 0.7, 0.2);
    rotMat.emissiveColor = new BABYLON.Color3(0.1, 0.35, 0.1);
    rotHandle.material = rotMat;
    rotHandle.isPickable = true;
    rotHandle.metadata = { handleType: 'rotate', cutoutId: cutout.id };

    handleMeshesRef.current.push(rotHandle);

    // Line to rotation handle
    const points = [
      new BABYLON.Vector3(cx, cy + halfH, 12),
      new BABYLON.Vector3(cx, cy + halfH + 20, 12)
    ];
    const line = BABYLON.MeshBuilder.CreateLines('rotLine', { points }, scene);
    line.color = new BABYLON.Color3(0.2, 0.7, 0.2);
    handleMeshesRef.current.push(line);
  };

  // Get cutout bounds
  const getCutoutBounds = (cutout) => {
    // Circular/polygonal shapes with diameter
    if (['SH', 'HX', 'HR', 'ST', 'PT', 'OC'].includes(cutout.type)) {
      const r = (cutout.diameter || 60) / 2;
      return { halfWidth: r, halfHeight: r };
    }
    // Oval shape with width and height
    if (cutout.type === 'OV') {
      return { 
        halfWidth: (cutout.width || 100) / 2, 
        halfHeight: (cutout.height || 60) / 2 
      };
    }
    // Diamond shape (square rotated 45 degrees, uses width for both dimensions)
    if (cutout.type === 'DM') {
      const size = (cutout.width || 70) / 2;
      // For rotated square, diagonal gives actual bounds
      const diagonal = size * Math.sqrt(2);
      return { halfWidth: diagonal, halfHeight: diagonal };
    }
    if (cutout.type === 'PG' && cutout.points && cutout.points.length >= 3) {
      // Calculate bounding box for custom polygon
      const xs = cutout.points.map(p => p.x);
      const ys = cutout.points.map(p => p.y);
      const width = Math.max(...xs) - Math.min(...xs);
      const height = Math.max(...ys) - Math.min(...ys);
      return { halfWidth: width / 2, halfHeight: height / 2 };
    }
    // Default for rectangle, triangle, etc.
    return { 
      halfWidth: (cutout.width || 100) / 2, 
      halfHeight: (cutout.height || 80) / 2 
    };
  };

  // Pointer event handlers - SMOOTH continuous updates
  const handlePointer = (info) => {
    const scene = sceneRef.current;
    if (!scene) return;

    switch (info.type) {
      case BABYLON.PointerEventTypes.POINTERDOWN:
        handlePointerDown(scene);
        break;
      case BABYLON.PointerEventTypes.POINTERMOVE:
        handlePointerMove(scene);
        break;
      case BABYLON.PointerEventTypes.POINTERUP:
        handlePointerUp();
        break;
    }
  };

  const handlePointerDown = (scene) => {
    const pick = scene.pick(scene.pointerX, scene.pointerY);
    lastPointerRef.current = { x: scene.pointerX, y: scene.pointerY };
    
    // Convert screen position to glass coordinates
    const getGlassCoordinates = () => {
      const camera = cameraRef.current;
      if (!camera) return { x: 0, y: 0, valid: false };
      
      // For orthographic camera, directly unproject the screen coordinates
      const canvas = canvasRef.current;
      if (!canvas) return { x: 0, y: 0, valid: false };
      
      // Get normalized device coordinates
      const ndcX = (scene.pointerX / canvas.width) * 2 - 1;
      const ndcY = -((scene.pointerY / canvas.height) * 2 - 1);
      
      // Calculate world coordinates from NDC for orthographic camera
      const orthoWidth = camera.orthoRight - camera.orthoLeft;
      const orthoHeight = camera.orthoTop - camera.orthoBottom;
      
      const worldX = ndcX * (orthoWidth / 2);
      const worldY = ndcY * (orthoHeight / 2);
      
      const scale = getScale();
      const glassWidth = configRef.current.width_mm;
      const glassHeight = configRef.current.height_mm;
      
      const clickX = worldX / scale + glassWidth / 2;
      const clickY = worldY / scale + glassHeight / 2;
      
      if (clickX >= 0 && clickX <= glassWidth && clickY >= 0 && clickY <= glassHeight) {
        return { x: clickX, y: clickY, valid: true };
      }
      return { x: 0, y: 0, valid: false };
    };
    
    // Polygon drawing mode
    if (isDrawingPolygonRef.current) {
      const coords = getGlassCoordinates();
      if (coords.valid) {
        handlePolygonDrawClick(coords.x, coords.y);
      }
      return;
    }
    
    // Measurement mode
    if (isMeasuringRef.current) {
      const coords = getGlassCoordinates();
      if (coords.valid) {
        handleMeasurementClick(coords.x, coords.y);
      }
      return;
    }
    
    // Placement mode
    if (isPlacementModeRef.current) {
      const coords = getGlassCoordinates();
      if (coords.valid) {
        placeCutoutAt(coords.x, coords.y);
        setIsPlacementMode(false);
        isPlacementModeRef.current = false;
      }
      return;
    }

    // Handle picked
    if (pick.hit && pick.pickedMesh?.metadata?.handleType) {
      pendingDragRef.current = true;
      dragStartPosRef.current = { x: scene.pointerX, y: scene.pointerY };
      dragTypeRef.current = pick.pickedMesh.metadata.handleType;
      dragDataRef.current = {
        cutoutId: pick.pickedMesh.metadata.cutoutId,
        handlePos: pick.pickedMesh.metadata.position
      };
      return;
    }

    // Cutout picked
    if (pick.hit && pick.pickedMesh?.metadata?.cutoutId) {
      pendingDragRef.current = true;
      dragStartPosRef.current = { x: scene.pointerX, y: scene.pointerY };
      dragTypeRef.current = 'move';
      dragDataRef.current = { cutoutId: pick.pickedMesh.metadata.cutoutId };
      setSelectedCutoutId(pick.pickedMesh.metadata.cutoutId);
      selectedCutoutIdRef.current = pick.pickedMesh.metadata.cutoutId;
      return;
    }

    // Empty space - deselect
    setSelectedCutoutId(null);
    selectedCutoutIdRef.current = null;
  };

  const handlePointerMove = (scene) => {
    // Check if we should activate drag (threshold check)
    if (pendingDragRef.current && dragStartPosRef.current && !isDraggingRef.current) {
      const dx = scene.pointerX - dragStartPosRef.current.x;
      const dy = scene.pointerY - dragStartPosRef.current.y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      
      // Activate drag only if moved >5px
      if (distance > 5) {
        isDraggingRef.current = true;
        pendingDragRef.current = false;
        if (cameraRef.current) cameraRef.current.detachControl();
      }
    }
    
    if (!isDraggingRef.current || !dragDataRef.current) return;

    const deltaX = scene.pointerX - lastPointerRef.current.x;
    const deltaY = scene.pointerY - lastPointerRef.current.y;
    lastPointerRef.current = { x: scene.pointerX, y: scene.pointerY };

    if (dragTypeRef.current === 'move') {
      moveCutoutSmooth(dragDataRef.current.cutoutId, deltaX, deltaY);
    } else if (dragTypeRef.current === 'resize') {
      resizeCutoutSmooth(dragDataRef.current.cutoutId, deltaX, deltaY, dragDataRef.current.handlePos);
    } else if (dragTypeRef.current === 'rotate') {
      rotateCutoutSmooth(dragDataRef.current.cutoutId, deltaX);
    }
  };

  const handlePointerUp = () => {
    if (isDraggingRef.current) {
      isDraggingRef.current = false;
      if (cameraRef.current && canvasRef.current) {
        cameraRef.current.attachControl(canvasRef.current, true);
      }
      // Price will be calculated via debounced effect
    }
    // Clear pending drag and drag data
    pendingDragRef.current = false;
    dragTypeRef.current = null;
    dragDataRef.current = null;
    dragStartPosRef.current = null;
  };

  // Smooth cutout movement - update state directly for reliability
  const moveCutoutSmooth = (cutoutId, deltaX, deltaY) => {
    const cam = cameraRef.current;
    if (!cam) return;
    
    const orthoWidth = cam.orthoRight - cam.orthoLeft;
    const canvasWidth = canvasRef.current?.width || 800;
    const pixelToWorld = orthoWidth / canvasWidth;
    const scale = getScale();
    
    const mmDeltaX = (deltaX * pixelToWorld) / scale;
    const mmDeltaY = (-deltaY * pixelToWorld) / scale;
    
    // Update state directly - this is more reliable
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      
      return {
        ...item,
        cutouts: item.cutouts.map(c => {
          if (c.id !== cutoutId) return c;
          
          const bounds = getCutoutBounds(c);
          const minX = bounds.halfWidth + 5;
          const maxX = item.width_mm - bounds.halfWidth - 5;
          const minY = bounds.halfHeight + 5;
          const maxY = item.height_mm - bounds.halfHeight - 5;
          
          let newX = c.x + mmDeltaX;
          let newY = c.y + mmDeltaY;
          
          // Apply snap-to-grid if enabled
          if (snapEnabledRef.current) {
            newX = Math.round(newX / snapGridSizeRef.current) * snapGridSizeRef.current;
            newY = Math.round(newY / snapGridSizeRef.current) * snapGridSizeRef.current;
          }
          
          return { 
            ...c, 
            x: Math.max(minX, Math.min(maxX, newX)),
            y: Math.max(minY, Math.min(maxY, newY))
          };
        })
      };
    }));
    
    // Update edge distance labels in real-time
    requestAnimationFrame(() => updateEdgeDistanceLabels(cutoutId));
  };

  // Smooth cutout resize - update state directly
  const resizeCutoutSmooth = (cutoutId, deltaX, deltaY, handlePos) => {
    const cam = cameraRef.current;
    if (!cam) return;
    
    const orthoWidth = cam.orthoRight - cam.orthoLeft;
    const canvasWidth = canvasRef.current?.width || 800;
    const pixelToWorld = orthoWidth / canvasWidth;
    const scale = getScale();
    
    const mmDeltaX = (deltaX * pixelToWorld) / scale;
    const mmDeltaY = (-deltaY * pixelToWorld) / scale;
    
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      
      return {
        ...item,
        cutouts: item.cutouts.map(c => {
          if (c.id !== cutoutId) return c;
          
          const isCircular = ['SH', 'HX', 'HR', 'ST', 'PT', 'OC'].includes(c.type);
          
          if (isCircular) {
            const delta = (Math.abs(mmDeltaX) > Math.abs(mmDeltaY) ? mmDeltaX : mmDeltaY) * 
                         (handlePos?.includes('r') || handlePos?.includes('t') ? 1 : -1);
            const newDiameter = Math.max(20, Math.min(300, (c.diameter || 50) + delta * 2));
            return { ...c, diameter: newDiameter };
          } else {
            let newWidth = c.width || 100;
            let newHeight = c.height || 80;
            
            if (handlePos?.includes('r')) newWidth += mmDeltaX * 2;
            if (handlePos?.includes('l')) newWidth -= mmDeltaX * 2;
            if (handlePos?.includes('t')) newHeight += mmDeltaY * 2;
            if (handlePos?.includes('b')) newHeight -= mmDeltaY * 2;
            
            return { 
              ...c, 
              width: Math.max(30, Math.min(400, newWidth)),
              height: Math.max(30, Math.min(400, newHeight))
            };
          }
        })
      };
    }));
    
    // Update edge distance labels in real-time
    requestAnimationFrame(() => updateEdgeDistanceLabels(cutoutId));
  };

  // Smooth cutout rotation - update state directly
  const rotateCutoutSmooth = (cutoutId, deltaX) => {
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      
      return {
        ...item,
        cutouts: item.cutouts.map(c => {
          if (c.id !== cutoutId) return c;
          return { ...c, rotation: ((c.rotation || 0) + deltaX * 0.5) % 360 };
        })
      };
    }));
  };

  // Update cutout dimensions directly (for input fields)
  const updateCutoutDimension = (cutoutId, field, value) => {
    const numValue = parseFloat(value) || 0;
    const clampedValue = Math.max(20, Math.min(400, numValue));
    
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      
      return {
        ...item,
        cutouts: item.cutouts.map(c => {
          if (c.id !== cutoutId) return c;
          return { ...c, [field]: clampedValue };
        })
      };
    }));
  };

  // Update cutout position directly (for input fields)
  const updateCutoutPosition = (cutoutId, field, value) => {
    const numValue = parseFloat(value) || 0;
    
    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      
      return {
        ...item,
        cutouts: item.cutouts.map(c => {
          if (c.id !== cutoutId) return c;
          
          const bounds = getCutoutBounds(c);
          let clampedValue = numValue;
          
          if (field === 'x') {
            clampedValue = Math.max(bounds.halfWidth + 5, Math.min(item.width_mm - bounds.halfWidth - 5, numValue));
          } else if (field === 'y') {
            clampedValue = Math.max(bounds.halfHeight + 5, Math.min(item.height_mm - bounds.halfHeight - 5, numValue));
          }
          
          return { ...c, [field]: clampedValue };
        })
      };
    }));
  };

  // Place new cutout
  const placeCutoutAt = (x, y) => {
    const shapeConfig = CUTOUT_SHAPES.find(s => s.id === selectedCutoutTypeRef.current);
    if (!shapeConfig) return;

    // Apply snap-to-grid if enabled
    const finalX = snapEnabled ? snapToGrid(x) : x;
    const finalY = snapEnabled ? snapToGrid(y) : y;

    const newCutout = {
      id: `cutout_${Date.now()}`,
      type: selectedCutoutTypeRef.current,
      x: Math.max(50, Math.min(configRef.current.width_mm - 50, finalX)),
      y: Math.max(50, Math.min(configRef.current.height_mm - 50, finalY)),
      rotation: 0,
      ...shapeConfig.defaultSize
    };

    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      return { ...item, cutouts: [...item.cutouts, newCutout] };
    }));

    setSelectedCutoutId(newCutout.id);
    selectedCutoutIdRef.current = newCutout.id;
    toast.success(`${shapeConfig.name} placed!`);
  };

  // Snap value to grid
  const snapToGrid = (value) => {
    return Math.round(value / snapGridSize) * snapGridSize;
  };

  // Copy/Duplicate selected cutout
  const duplicateCutout = (cutoutId) => {
    const cutout = config.cutouts.find(c => c.id === cutoutId);
    if (!cutout) return;

    const offset = 30; // Offset position for duplicate
    const newCutout = {
      ...cutout,
      id: `cutout_${Date.now()}`,
      x: Math.min(config.width_mm - 50, cutout.x + offset),
      y: Math.min(config.height_mm - 50, cutout.y + offset),
    };

    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      return { ...item, cutouts: [...item.cutouts, newCutout] };
    }));

    setSelectedCutoutId(newCutout.id);
    selectedCutoutIdRef.current = newCutout.id;
    toast.success('Cutout duplicated!');
  };

  // Place cutout from template
  const placeFromTemplate = (template) => {
    const newCutout = {
      id: `cutout_${Date.now()}`,
      type: template.type,
      x: config.width_mm / 2, // Center
      y: config.height_mm / 2,
      rotation: 0,
      diameter: template.diameter,
      width: template.width,
      height: template.height,
    };

    setGlassItems(prev => prev.map((item, idx) => {
      if (idx !== activeItemIndexRef.current) return item;
      return { ...item, cutouts: [...item.cutouts, newCutout] };
    }));

    setSelectedCutoutId(newCutout.id);
    selectedCutoutIdRef.current = newCutout.id;
    setShowTemplates(false);
    toast.success(`${template.name} added!`);
  };

  // Apply preset size to selected cutout
  const applyPresetSize = (size) => {
    if (!selectedCutoutId) return;
    
    const cutout = config.cutouts.find(c => c.id === selectedCutoutId);
    if (!cutout) return;

    if (['SH', 'HX', 'HR'].includes(cutout.type)) {
      updateCutoutDimension(selectedCutoutId, 'diameter', size);
    } else {
      // For rectangles, apply as width (maintain aspect ratio option could be added)
      updateCutoutDimension(selectedCutoutId, 'width', size);
    }
    toast.success(`Size set to ${size}mm`);
  };

  // Remove cutout
  const removeCutout = (cutoutId) => {
    updateCurrentItem({
      cutouts: config.cutouts.filter(c => c.id !== cutoutId)
    });
    setSelectedCutoutId(null);
    toast.success('Cutout removed');
  };

  // Zoom controls - ONLY affects camera, not glass
  const handleZoom = (direction) => {
    if (!cameraRef.current) return;
    const cam = cameraRef.current;
    const factor = direction === 'in' ? 0.85 : 1.18;
    cam.orthoLeft *= factor;
    cam.orthoRight *= factor;
    cam.orthoTop *= factor;
    cam.orthoBottom *= factor;
  };

  const resetView = () => {
    if (!cameraRef.current) return;
    const cam = cameraRef.current;
    cam.orthoLeft = -350;
    cam.orthoRight = 350;
    cam.orthoTop = 280;
    cam.orthoBottom = -280;
  };

  // Calculate prices
  const calculateAllPrices = async () => {
    if (!pricingConfig) return;
    setCalculatingPrice(true);
    
    try {
      let total = 0;
      const updatedItems = await Promise.all(glassItems.map(async (item) => {
        const response = await fetch(`${API_URL}/erp/glass-config/calculate-price`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            glass_type: item.glass_type,
            thickness_mm: item.thickness_mm,
            color_id: item.color_id,
            color_name: item.color_name,
            application: item.application,
            width_mm: item.width_mm,
            height_mm: item.height_mm,
            holes_cutouts: item.cutouts.map(c => ({
              id: c.id,
              shape: ['SH', 'HX', 'HR'].includes(c.type) ? 'circle' : 'rectangle',
              diameter_mm: c.diameter,
              width_mm: c.width,
              height_mm: c.height,
            })),
            quantity: item.quantity,
            needs_transport: false
          })
        });
        
        if (response.ok) {
          const data = await response.json();
          total += data.total;
          return { ...item, item_price: data.total };
        }
        return item;
      }));
      
      setGlassItems(updatedItems);
      setOrderTotal(total);
    } catch (error) {
      console.error('Price calculation failed:', error);
    } finally {
      setCalculatingPrice(false);
    }
  };

  // Calculate price on config change
  useEffect(() => {
    const timer = setTimeout(() => {
      if (pricingConfig) calculateAllPrices();
    }, 500);
    return () => clearTimeout(timer);
  }, [config.glass_type, config.thickness_mm, config.color_id, config.application, config.width_mm, config.height_mm, config.quantity, pricingConfig]);

  // Add glass item
  const addGlassItem = () => {
    const newId = glassItems.length + 1;
    setGlassItems(prev => [...prev, createDefaultGlassItem(newId)]);
    setActiveItemIndex(glassItems.length);
    setSelectedCutoutId(null);
    toast.success(`Glass ${newId} added`);
  };

  // Enter placement mode
  const enterPlacementMode = (shapeType) => {
    setSelectedCutoutType(shapeType);
    selectedCutoutTypeRef.current = shapeType;
    setIsPlacementMode(true);
    isPlacementModeRef.current = true;
    setSelectedCutoutId(null);
    setOpenDropdown(null);
    toast.info(`Click on glass to place ${CUTOUT_SHAPES.find(s => s.id === shapeType)?.name}`);
  };

  // Dropdown render function (memoized)
  const renderDropdown = useCallback(({ label, value, options, onChange, renderOption }) => {
    const isOpen = openDropdown === label;
    return (
      <div className="relative">
        <button
          onClick={() => setOpenDropdown(isOpen ? null : label)}
          className="w-full flex items-center justify-between px-3 py-2 bg-white border rounded-lg text-sm hover:bg-gray-50"
        >
          <span className="truncate">{value}</span>
          <ChevronDown className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
        </button>
        {isOpen && (
          <div className="absolute z-50 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-48 overflow-y-auto">
            {options.map((opt, idx) => (
              <button
                key={idx}
                onClick={() => { onChange(opt); setOpenDropdown(null); }}
                className="w-full px-3 py-2 text-left text-sm hover:bg-blue-50 flex items-center gap-2"
              >
                {renderOption ? renderOption(opt) : opt.label || opt.name || opt}
              </button>
            ))}
          </div>
        )}
      </div>
    );
  }, [openDropdown]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50" onClick={() => setOpenDropdown(null)}>
      {/* Header */}
      <div className="bg-white border-b shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-3">
          <h1 className="text-xl font-bold text-gray-800 text-center">Book Your Glass</h1>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-4">
        <div className="grid lg:grid-cols-3 gap-4">
          {/* Left Panel - Configuration with Dropdowns */}
          <div className="lg:col-span-1 space-y-3">
            {/* Glass Config Dropdowns */}
            <div className="bg-white rounded-xl shadow-sm p-3 space-y-3" onClick={e => e.stopPropagation()}>
              <h3 className="text-sm font-semibold text-gray-700">Glass Configuration</h3>
              
              {/* Glass Type */}
              <div>
                <label className="text-xs text-gray-500 mb-1 block">Glass Type</label>
                {renderDropdown({
                  label: "glass_type",
                  value: pricingConfig?.glass_types?.find(g => g.glass_type === config.glass_type)?.display_name || 'Select',
                  options: pricingConfig?.glass_types?.filter(g => g.active) || [],
                  onChange: (opt) => updateCurrentItem({ glass_type: opt.glass_type }),
                  renderOption: (opt) => opt.display_name
                })}
              </div>

              {/* Thickness */}
              <div>
                <label className="text-xs text-gray-500 mb-1 block">Thickness</label>
                {renderDropdown({
                  label: "thickness",
                  value: `${config.thickness_mm}mm`,
                  options: pricingConfig?.thickness_options?.filter(t => t.active) || [],
                  onChange: (opt) => updateCurrentItem({ thickness_mm: opt.thickness_mm }),
                  renderOption: (opt) => opt.display_name
                })}
              </div>

              {/* Color */}
              <div>
                <label className="text-xs text-gray-500 mb-1 block">Color</label>
                {renderDropdown({
                  label: "color",
                  value: config.color_name,
                  options: pricingConfig?.colors?.filter(c => c.active) || [],
                  onChange: (opt) => updateCurrentItem({ 
                    color_id: opt.color_id, 
                    color_name: opt.color_name,
                    color_hex: opt.hex_code 
                  }),
                  renderOption: (opt) => (
                    <>
                      <span className="w-4 h-4 rounded-full border" style={{ backgroundColor: opt.hex_code }}></span>
                      {opt.color_name}
                    </>
                  )
                })}
              </div>

              {/* Application */}
              <div>
                <label className="text-xs text-gray-500 mb-1 block">Application</label>
                {renderDropdown({
                  label: "application",
                  value: pricingConfig?.applications?.find(a => a.application_id === config.application)?.application_name || 'Select',
                  options: pricingConfig?.applications?.filter(a => a.active) || [],
                  onChange: (opt) => updateCurrentItem({ application: opt.application_id }),
                  renderOption: (opt) => opt.application_name
                })}
              </div>

              {/* Size */}
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-xs text-gray-500 mb-1 block">Width (mm)</label>
                  <input
                    type="number"
                    value={config.width_mm}
                    onChange={(e) => updateCurrentItem({ width_mm: parseFloat(e.target.value) || 0 })}
                    className="w-full h-9 rounded-lg border px-2 text-sm"
                    data-testid="width-input"
                  />
                </div>
                <div>
                  <label className="text-xs text-gray-500 mb-1 block">Height (mm)</label>
                  <input
                    type="number"
                    value={config.height_mm}
                    onChange={(e) => updateCurrentItem({ height_mm: parseFloat(e.target.value) || 0 })}
                    className="w-full h-9 rounded-lg border px-2 text-sm"
                    data-testid="height-input"
                  />
                </div>
              </div>
              
              {/* Quick Size Presets */}
              <div className="mt-2">
                <label className="text-[10px] text-gray-400 mb-1 block">Quick Sizes</label>
                <div className="flex flex-wrap gap-1">
                  {[
                    { w: 600, h: 900, label: '600×900' },
                    { w: 900, h: 1200, label: '900×1200' },
                    { w: 1000, h: 2100, label: '1m×2.1m Door' },
                    { w: 1200, h: 2400, label: '1.2m×2.4m' },
                    { w: 500, h: 500, label: '500×500' },
                  ].map(size => (
                    <button
                      key={size.label}
                      onClick={() => updateCurrentItem({ width_mm: size.w, height_mm: size.h })}
                      className={`px-2 py-1 text-[9px] rounded border transition-all ${
                        config.width_mm === size.w && config.height_mm === size.h
                          ? 'bg-blue-600 text-white border-blue-600'
                          : 'bg-gray-50 hover:bg-blue-50 border-gray-200'
                      }`}
                    >
                      {size.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Cutouts */}
            <div className="bg-white rounded-xl shadow-sm p-3" onClick={e => e.stopPropagation()}>
              <h3 className="text-sm font-semibold text-gray-700 mb-2">
                Add Cutouts
                {isPlacementMode && <span className="ml-2 text-xs text-blue-600 animate-pulse">(Click on glass)</span>}
                {isDrawingPolygon && <span className="ml-2 text-xs text-teal-600 animate-pulse">(Drawing...)</span>}
              </h3>
              
              {/* Standard Shapes */}
              <div className="grid grid-cols-5 gap-1 mb-2">
                {CUTOUT_SHAPES.filter(s => !s.isCorner && !s.isCustom).map(shape => {
                  const Icon = shape.icon;
                  return (
                    <button
                      key={shape.id}
                      onClick={() => enterPlacementMode(shape.id)}
                      className={`p-2 rounded-lg text-xs flex flex-col items-center gap-0.5 transition-all ${
                        isPlacementMode && selectedCutoutType === shape.id
                          ? 'bg-blue-600 text-white'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                      }`}
                      data-testid={`shape-${shape.id}`}
                      title={shape.name}
                    >
                      <Icon className="w-4 h-4" />
                      <span className="text-[10px]">{shape.name}</span>
                    </button>
                  );
                })}
              </div>
              
              {/* Special Shapes: Corner Notch & Freeform */}
              <div className="flex gap-1 mb-2">
                {/* Corner Notch Dropdown */}
                <div className="flex-1 relative">
                  <button
                    onClick={() => setOpenDropdown(openDropdown === 'corner' ? null : 'corner')}
                    className="w-full p-2 rounded-lg text-xs flex items-center justify-center gap-1 bg-red-50 text-red-700 hover:bg-red-100 border border-red-200"
                    data-testid="corner-notch-btn"
                  >
                    <CornerDownRight className="w-4 h-4" />
                    <span>Corner Notch</span>
                    <ChevronDown className="w-3 h-3" />
                  </button>
                  {openDropdown === 'corner' && (
                    <div className="absolute z-50 left-0 right-0 mt-1 bg-white border rounded-lg shadow-lg p-2">
                      <p className="text-[10px] text-gray-500 mb-1">Select Corner:</p>
                      <div className="grid grid-cols-2 gap-1">
                        {CORNER_POSITIONS.map(corner => (
                          <button
                            key={corner.id}
                            onClick={() => { placeCornerNotch(corner.id); setOpenDropdown(null); }}
                            className="p-1.5 text-[10px] bg-red-50 hover:bg-red-100 rounded border border-red-200"
                          >
                            {corner.name}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
                
                {/* Freeform Drawing */}
                <button
                  onClick={() => {
                    setIsDrawingPolygon(true);
                    isDrawingPolygonRef.current = true;
                    setPolygonPoints([]);
                    setIsPlacementMode(false);
                    isPlacementModeRef.current = false;
                    toast.info('Click points on glass to draw polygon');
                  }}
                  className={`flex-1 p-2 rounded-lg text-xs flex items-center justify-center gap-1 transition-all ${
                    isDrawingPolygon ? 'bg-teal-600 text-white' : 'bg-teal-50 text-teal-700 hover:bg-teal-100 border border-teal-200'
                  }`}
                  data-testid="freeform-btn"
                >
                  <PenTool className="w-4 h-4" />
                  <span>Freeform</span>
                </button>
              </div>

              {isPlacementMode && (
                <Button
                  onClick={() => { setIsPlacementMode(false); isPlacementModeRef.current = false; }}
                  variant="outline"
                  size="sm"
                  className="w-full h-8 text-xs"
                >
                  Cancel
                </Button>
              )}

              {/* Selected cutout info with dimension inputs */}
              {selectedCutout && !isPlacementMode && !isDrawingPolygon && (
                <div className="mt-2 p-2 bg-blue-50 rounded-lg border border-blue-200 text-xs">
                  <div className="flex justify-between items-center mb-2">
                    <span className="font-semibold text-blue-800">
                      {CUTOUT_SHAPES.find(s => s.id === selectedCutout.type)?.name} Selected
                    </span>
                    <div className="flex gap-1">
                      <button 
                        onClick={() => duplicateCutout(selectedCutout.id)} 
                        className="text-blue-600 hover:text-blue-800 p-1 rounded hover:bg-blue-100"
                        title="Duplicate"
                      >
                        <Copy className="w-3 h-3" />
                      </button>
                      <button 
                        onClick={() => removeCutout(selectedCutout.id)} 
                        className="text-red-500 hover:text-red-700 p-1 rounded hover:bg-red-100"
                        title="Remove"
                      >
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                  
                  {/* Preset Size Buttons */}
                  {['SH', 'HX', 'HR'].includes(selectedCutout.type) && (
                    <div className="mb-2">
                      <p className="text-[10px] font-medium text-gray-600 uppercase mb-1">Quick Sizes (mm)</p>
                      <div className="flex flex-wrap gap-1">
                        {PRESET_HOLE_SIZES.map(size => (
                          <button
                            key={size}
                            onClick={() => applyPresetSize(size)}
                            className={`px-2 py-1 rounded text-[10px] transition-all ${
                              Math.round(selectedCutout.diameter) === size 
                                ? 'bg-blue-600 text-white' 
                                : 'bg-white border hover:bg-gray-100'
                            }`}
                          >
                            Ø{size}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                  
                  {/* Dimension Input Fields */}
                  <div className="space-y-2 mb-2">
                    <p className="text-[10px] font-medium text-gray-600 uppercase">Dimensions (mm)</p>
                    
                    {['SH', 'HX', 'HR', 'ST', 'PT', 'OC'].includes(selectedCutout.type) ? (
                      // Circular/polygonal shapes - diameter only
                      <div className="flex items-center gap-2">
                        <label className="text-gray-500 w-12">Ø</label>
                        <input
                          type="number"
                          value={Math.round(selectedCutout.diameter || 60)}
                          onChange={(e) => updateCutoutDimension(selectedCutout.id, 'diameter', e.target.value)}
                          className="flex-1 h-7 px-2 rounded border text-xs text-center"
                          min="20"
                          max="400"
                          data-testid="cutout-diameter-input"
                        />
                        <span className="text-gray-400 text-[10px]">mm</span>
                      </div>
                    ) : selectedCutout.type === 'DM' ? (
                      // Diamond - single size (square rotated)
                      <div className="flex items-center gap-2">
                        <label className="text-gray-500 w-12">Size</label>
                        <input
                          type="number"
                          value={Math.round(selectedCutout.width || 70)}
                          onChange={(e) => {
                            updateCutoutDimension(selectedCutout.id, 'width', e.target.value);
                            updateCutoutDimension(selectedCutout.id, 'height', e.target.value);
                          }}
                          className="flex-1 h-7 px-2 rounded border text-xs text-center"
                          min="20"
                          max="400"
                        />
                        <span className="text-gray-400 text-[10px]">mm</span>
                      </div>
                    ) : (
                      // Rectangular/Triangle shapes - width & height
                      <div className="grid grid-cols-2 gap-2">
                        <div className="flex items-center gap-1">
                          <label className="text-gray-500 text-[10px]">W</label>
                          <input
                            type="number"
                            value={Math.round(selectedCutout.width || 100)}
                            onChange={(e) => updateCutoutDimension(selectedCutout.id, 'width', e.target.value)}
                            className="flex-1 h-7 px-2 rounded border text-xs text-center"
                            min="30"
                            max="400"
                            data-testid="cutout-width-input"
                          />
                        </div>
                        <div className="flex items-center gap-1">
                          <label className="text-gray-500 text-[10px]">H</label>
                          <input
                            type="number"
                            value={Math.round(selectedCutout.height || 80)}
                            onChange={(e) => updateCutoutDimension(selectedCutout.id, 'height', e.target.value)}
                            className="flex-1 h-7 px-2 rounded border text-xs text-center"
                            min="30"
                            max="400"
                            data-testid="cutout-height-input"
                          />
                        </div>
                      </div>
                    )}
                    
                    {/* Position Input Fields */}
                    <p className="text-[10px] font-medium text-gray-600 uppercase mt-2">Position (mm from bottom-left)</p>
                    <div className="grid grid-cols-2 gap-2">
                      <div className="flex items-center gap-1">
                        <label className="text-gray-500 text-[10px]">X</label>
                        <input
                          type="number"
                          value={Math.round(selectedCutout.x || 0)}
                          onChange={(e) => updateCutoutPosition(selectedCutout.id, 'x', e.target.value)}
                          className="flex-1 h-7 px-2 rounded border text-xs text-center"
                          data-testid="cutout-x-input"
                        />
                      </div>
                      <div className="flex items-center gap-1">
                        <label className="text-gray-500 text-[10px]">Y</label>
                        <input
                          type="number"
                          value={Math.round(selectedCutout.y || 0)}
                          onChange={(e) => updateCutoutPosition(selectedCutout.id, 'y', e.target.value)}
                          className="flex-1 h-7 px-2 rounded border text-xs text-center"
                          data-testid="cutout-y-input"
                        />
                      </div>
                    </div>
                    
                    {/* Rotation */}
                    {selectedCutout.rotation !== 0 && (
                      <div className="flex items-center gap-2 mt-1">
                        <label className="text-gray-500 text-[10px]">Rotation</label>
                        <span className="text-gray-700">{Math.round(selectedCutout.rotation)}°</span>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Snap to Grid & Templates */}
              <div className="mt-2 flex gap-2">
                <button
                  onClick={() => setSnapEnabled(!snapEnabled)}
                  className={`flex-1 flex items-center justify-center gap-1 px-2 py-1.5 rounded text-[10px] transition-all ${
                    snapEnabled ? 'bg-green-100 text-green-700 border border-green-300' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                  title="Snap to Grid"
                >
                  <Magnet className="w-3 h-3" />
                  Snap {snapEnabled ? 'ON' : 'OFF'}
                </button>
                <button
                  onClick={() => setShowTemplates(!showTemplates)}
                  className={`flex-1 flex items-center justify-center gap-1 px-2 py-1.5 rounded text-[10px] transition-all ${
                    showTemplates ? 'bg-purple-100 text-purple-700 border border-purple-300' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                  title="Templates"
                >
                  <LayoutTemplate className="w-3 h-3" />
                  Templates
                </button>
              </div>

              {/* Snap Grid Size Selector */}
              {snapEnabled && (
                <div className="mt-2 p-2 bg-green-50 rounded-lg border border-green-200">
                  <p className="text-[10px] font-medium text-green-700 mb-1">Grid Size (mm)</p>
                  <div className="flex gap-1">
                    {SNAP_GRID_SIZES.map(size => (
                      <button
                        key={size}
                        onClick={() => setSnapGridSize(size)}
                        className={`flex-1 px-2 py-1 rounded text-[10px] transition-all ${
                          snapGridSize === size 
                            ? 'bg-green-600 text-white' 
                            : 'bg-white border hover:bg-green-100'
                        }`}
                      >
                        {size}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Templates Panel */}
              {showTemplates && (
                <div className="mt-2 p-2 bg-purple-50 rounded-lg border border-purple-200">
                  <p className="text-[10px] font-medium text-purple-700 mb-2">Quick Templates</p>
                  <div className="space-y-1 max-h-28 overflow-y-auto">
                    {CUTOUT_TEMPLATES.map(template => (
                      <button
                        key={template.id}
                        onClick={() => placeFromTemplate(template)}
                        className="w-full text-left p-1.5 bg-white rounded border hover:bg-purple-100 transition-all"
                      >
                        <div className="flex justify-between items-center">
                          <span className="text-[10px] font-medium text-gray-800">{template.name}</span>
                          <span className="text-[9px] text-gray-500">
                            {template.diameter ? `Ø${template.diameter}` : `${template.width}×${template.height}`}
                          </span>
                        </div>
                      </button>
                    ))}
                  </div>
                  
                  {/* Door Fittings Section */}
                  <div className="mt-3 pt-2 border-t border-purple-200">
                    <div className="flex justify-between items-center mb-2">
                      <p className="text-[10px] font-bold text-amber-700 flex items-center gap-1">
                        🚪 Door Fittings
                      </p>
                      {/* Quick Door Setup Button */}
                      <button
                        onClick={quickDoorSetup}
                        className="px-2 py-1 bg-gradient-to-r from-amber-500 to-orange-500 text-white rounded text-[9px] font-bold hover:from-amber-600 hover:to-orange-600 shadow-sm flex items-center gap-1"
                        title="Add all door fittings at once: Handle + 3 Hinges + Lock"
                      >
                        ⚡ Quick Setup
                      </button>
                    </div>
                    
                    {/* Handles */}
                    <p className="text-[9px] text-gray-500 mb-1 font-medium">Handles</p>
                    <div className="grid grid-cols-3 gap-1 mb-2">
                      {DOOR_FITTINGS.filter(f => f.category === 'handle').map(fitting => (
                        <button
                          key={fitting.id}
                          onClick={() => placeDoorFitting(fitting)}
                          className="p-1 bg-white rounded border hover:bg-amber-100 transition-all text-center"
                          title={fitting.description}
                        >
                          <span className="text-[9px] font-medium text-gray-800">{fitting.icon} {fitting.name.split(' - ')[1]}</span>
                        </button>
                      ))}
                    </div>
                    
                    {/* Locks */}
                    <p className="text-[9px] text-gray-500 mb-1 font-medium">Locks</p>
                    <div className="grid grid-cols-2 gap-1 mb-2">
                      {DOOR_FITTINGS.filter(f => f.category === 'lock').map(fitting => (
                        <button
                          key={fitting.id}
                          onClick={() => placeDoorFitting(fitting)}
                          className="p-1 bg-white rounded border hover:bg-amber-100 transition-all text-center"
                          title={fitting.description}
                        >
                          <span className="text-[9px] font-medium text-gray-800">{fitting.icon} {fitting.name}</span>
                        </button>
                      ))}
                    </div>
                    
                    {/* Hinges */}
                    <p className="text-[9px] text-gray-500 mb-1 font-medium">Hinges</p>
                    <div className="grid grid-cols-3 gap-1 mb-2">
                      {DOOR_FITTINGS.filter(f => f.category === 'hinge').map(fitting => (
                        <button
                          key={fitting.id}
                          onClick={() => placeDoorFitting(fitting)}
                          className="p-1 bg-white rounded border hover:bg-amber-100 transition-all text-center"
                          title={fitting.description}
                        >
                          <span className="text-[9px] font-medium text-gray-800">{fitting.icon} {fitting.name.split(' - ')[1]}</span>
                        </button>
                      ))}
                    </div>
                    
                    {/* Floor Spring */}
                    <p className="text-[9px] text-gray-500 mb-1 font-medium">Floor Spring / Pivot</p>
                    <div className="grid grid-cols-3 gap-1">
                      {DOOR_FITTINGS.filter(f => f.category === 'floor_spring').map(fitting => (
                        <button
                          key={fitting.id}
                          onClick={() => placeDoorFitting(fitting)}
                          className="p-1 bg-white rounded border hover:bg-amber-100 transition-all text-center"
                          title={fitting.description}
                        >
                          <span className="text-[9px] font-medium text-gray-800">{fitting.icon} {fitting.name.split(' - ')[1] || fitting.name}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {/* Auto-Align Panel - shown when cutout is selected */}
              {selectedCutout && (
                <div className="mt-2 p-2 bg-indigo-50 rounded-lg border border-indigo-200">
                  <p className="text-[10px] font-bold text-indigo-700 mb-2">Auto-Align</p>
                  <div className="grid grid-cols-4 gap-1">
                    <button
                      onClick={() => autoAlignCutout('left')}
                      className="p-1.5 bg-white rounded border hover:bg-indigo-100 text-[9px] font-medium"
                      title="Align Left"
                    >
                      ◀ Left
                    </button>
                    <button
                      onClick={() => autoAlignCutout('centerH')}
                      className="p-1.5 bg-white rounded border hover:bg-indigo-100 text-[9px] font-medium"
                      title="Center Horizontal"
                    >
                      ↔ H-Center
                    </button>
                    <button
                      onClick={() => autoAlignCutout('centerV')}
                      className="p-1.5 bg-white rounded border hover:bg-indigo-100 text-[9px] font-medium"
                      title="Center Vertical"
                    >
                      ↕ V-Center
                    </button>
                    <button
                      onClick={() => autoAlignCutout('right')}
                      className="p-1.5 bg-white rounded border hover:bg-indigo-100 text-[9px] font-medium"
                      title="Align Right"
                    >
                      Right ▶
                    </button>
                    <button
                      onClick={() => autoAlignCutout('top')}
                      className="p-1.5 bg-white rounded border hover:bg-indigo-100 text-[9px] font-medium"
                      title="Align Top"
                    >
                      ▲ Top
                    </button>
                    <button
                      onClick={() => autoAlignCutout('center')}
                      className="p-1.5 bg-indigo-600 text-white rounded border hover:bg-indigo-700 text-[9px] font-medium col-span-2"
                      title="Center Both"
                    >
                      ⊕ Center Both
                    </button>
                    <button
                      onClick={() => autoAlignCutout('bottom')}
                      className="p-1.5 bg-white rounded border hover:bg-indigo-100 text-[9px] font-medium"
                      title="Align Bottom"
                    >
                      ▼ Bottom
                    </button>
                  </div>
                </div>
              )}

              {/* Cutout list */}
              {config.cutouts.length > 0 && (
                <div className="mt-2 space-y-1">
                  {config.cutouts.map((c, idx) => (
                    <div 
                      key={c.id}
                      onClick={() => { setSelectedCutoutId(c.id); selectedCutoutIdRef.current = c.id; }}
                      className={`p-1.5 rounded text-xs cursor-pointer flex justify-between ${
                        selectedCutoutId === c.id ? 'bg-blue-100 border border-blue-300' : 'bg-gray-50 hover:bg-gray-100'
                      }`}
                    >
                      <span>{CUTOUT_SHAPES.find(s => s.id === c.type)?.name} #{idx + 1}</span>
                      <span className="text-gray-500">
                        {['SH', 'HX', 'HR', 'ST', 'PT', 'OC'].includes(c.type) ? `Ø${Math.round(c.diameter)}` : 
                         c.type === 'DM' ? `${Math.round(c.width)}×${Math.round(c.width)}` :
                         `${Math.round(c.width)}×${Math.round(c.height)}`}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Real-time Price Display - Grand Total for ALL items */}
            {livePrice.itemsBreakdown.length > 0 && (
              <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl shadow-sm p-4 border-2 border-blue-200">
                <h3 className="text-sm font-bold text-blue-900 mb-3 flex items-center gap-2">
                  <Package className="w-4 h-4" /> Order Price Summary
                </h3>
                <div className="space-y-2 text-xs">
                  {/* Current Item Details */}
                  {config.cutouts.length > 0 && config.width_mm && config.height_mm && (
                    <div className="bg-white/50 rounded-lg p-2 mb-2">
                      <div className="text-[10px] font-semibold text-blue-800 mb-1">Glass #{activeItemIndex + 1} (Current)</div>
                      <div className="flex justify-between text-gray-700">
                        <span>Area: {currentPrice.area_sqft?.toFixed(2)} sq ft</span>
                        <span className="font-semibold">₹{currentPrice.basePrice?.toFixed(2)}</span>
                      </div>
                      <div className="flex justify-between text-gray-700">
                        <span>Cutouts: {config.cutouts.length} × ₹{pricingRules?.cutout_price ?? 50}</span>
                        <span className="font-semibold">₹{currentPrice.cutoutCharge}</span>
                      </div>
                      <div className="flex justify-between text-gray-700">
                        <span>Qty: {config.quantity || 1}</span>
                        <span className="font-semibold">₹{currentPrice.totalAmount?.toFixed(2)}</span>
                      </div>
                    </div>
                  )}
                  
                  {/* All Items Summary */}
                  {livePrice.itemsBreakdown.length > 1 && (
                    <div className="text-[10px] text-gray-600 mb-1">
                      {livePrice.itemsBreakdown.length} Glass Items Total:
                    </div>
                  )}
                  
                  <div className="border-t-2 border-blue-300 pt-2 mt-2">
                    <div className="flex justify-between text-blue-900 font-bold text-sm">
                      <span>GRAND TOTAL:</span>
                      <span>₹{livePrice.grandTotal?.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between text-green-700 font-semibold text-xs mt-1">
                      <span>Advance (50%):</span>
                      <span>₹{livePrice.advanceAmount?.toFixed(2)}</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Quantity */}
            <div className="bg-white rounded-xl shadow-sm p-3">
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Quantity</h3>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => updateCurrentItem({ quantity: Math.max(1, config.quantity - 1) })}
                  className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200"
                >
                  <Minus className="w-3 h-3" />
                </button>
                <input
                  type="number"
                  value={config.quantity}
                  onChange={(e) => updateCurrentItem({ quantity: Math.max(1, parseInt(e.target.value) || 1) })}
                  className="w-14 h-8 rounded-lg border text-center text-sm"
                />
                <button
                  onClick={() => updateCurrentItem({ quantity: config.quantity + 1 })}
                  className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center hover:bg-gray-200"
                >
                  <Plus className="w-3 h-3" />
                </button>
              </div>
            </div>

            {/* Add Another Glass */}
            <button
              onClick={addGlassItem}
              className="w-full py-2 border-2 border-dashed border-gray-300 rounded-xl text-gray-600 text-sm font-medium hover:border-blue-400 hover:text-blue-600 flex items-center justify-center gap-2"
              data-testid="add-glass-item-btn"
            >
              <Plus className="w-4 h-4" /> ADD ANOTHER GLASS
            </button>

            {/* Actions */}
            <div className="space-y-2">
              <Button 
                onClick={handleGenerateQuotation}
                disabled={config.cutouts.length === 0}
                className="w-full h-10 bg-gray-800 hover:bg-gray-900 text-white font-medium rounded-xl text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                GENERATE QUOTATION
              </Button>
              <Button 
                onClick={handleAddToOrder}
                disabled={addingToOrder || config.cutouts.length === 0}
                className="w-full h-10 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-xl flex items-center justify-center gap-2 text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {addingToOrder ? <Loader2 className="w-4 h-4 animate-spin" /> : <ShoppingCart className="w-4 h-4" />} 
                {addingToOrder ? 'SAVING...' : 'ADD TO ORDER'}
              </Button>
            </div>
          </div>

          {/* Right Panel - 3D Preview */}
          <div className={`${isFullscreen ? 'fixed inset-0 z-50 bg-gray-50' : 'lg:col-span-2'}`}>
            <div className={`bg-white ${isFullscreen ? 'h-full flex flex-col' : 'rounded-xl shadow-sm'} overflow-hidden`}>
              <div className="p-3 border-b bg-gray-50 flex-shrink-0">
                <div className="flex justify-between items-center mb-2">
                  <div>
                    <h3 className="text-sm font-semibold text-gray-800">Professional 3D Glass Design Canvas</h3>
                    <p className="text-[10px] text-gray-500">
                      {isDrawingPolygon ? '✏️ Click points to draw polygon (click near first point to close)' :
                       isPlacementMode ? '🎯 Click on glass to place shape' : 'Advanced CAD-like visualization • Drag to reposition'}
                    </p>
                  </div>
                  <div className="flex gap-1">
                    {/* Zoom Controls */}
                    <button onClick={() => handleZoom('in')} className="p-1.5 bg-gray-200 rounded hover:bg-gray-300" data-testid="zoom-in-btn" title="Zoom In">
                      <ZoomIn className="w-4 h-4" />
                    </button>
                    <button onClick={() => handleZoom('out')} className="p-1.5 bg-gray-200 rounded hover:bg-gray-300" data-testid="zoom-out-btn" title="Zoom Out">
                      <ZoomOut className="w-4 h-4" />
                    </button>
                    <button onClick={resetView} className="p-1.5 bg-gray-200 rounded hover:bg-gray-300" title="Reset View">
                      <RotateCcw className="w-4 h-4" />
                    </button>
                    <div className="w-px bg-gray-300 mx-1" />
                    {/* 3D View Rotation */}
                    <button onClick={() => rotate3DView('front')} className="p-1.5 bg-gray-200 rounded hover:bg-gray-300" title="Front View">
                      <Square className="w-4 h-4" />
                    </button>
                    <button onClick={() => rotate3DView('angle')} className="p-1.5 bg-gray-200 rounded hover:bg-gray-300" title="3D Angle View">
                      <Rotate3D className="w-4 h-4" />
                    </button>
                    <button onClick={() => rotate3DView('top')} className="p-1.5 bg-gray-200 rounded hover:bg-gray-300" title="Top View">
                      <Eye className="w-4 h-4" />
                    </button>
                    <div className="w-px bg-gray-300 mx-1" />
                    {/* Measurement Tool */}
                    <button 
                      onClick={toggleMeasurementMode}
                      className={`p-1.5 rounded ${isMeasuring ? 'bg-orange-500 text-white' : 'bg-gray-200 hover:bg-gray-300'}`}
                      title="Measure Distance"
                      data-testid="measure-btn"
                    >
                      <Ruler className="w-4 h-4" />
                    </button>
                    {measurePoints.length > 0 && (
                      <button 
                        onClick={clearMeasurements}
                        className="p-1.5 bg-red-100 text-red-600 rounded hover:bg-red-200"
                        title="Clear Measurements"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    )}
                    <div className="w-px bg-gray-300 mx-1" />
                    {/* Preview Size Toggles */}
                    <button 
                      onClick={() => setIsLargePreview(!isLargePreview)} 
                      className={`p-1.5 rounded ${isLargePreview ? 'bg-blue-600 text-white' : 'bg-gray-200 hover:bg-gray-300'}`}
                      title={isLargePreview ? "Normal Size (700px)" : "Large Preview (850px)"}
                    >
                      <Maximize2 className="w-4 h-4" />
                    </button>
                    <button 
                      onClick={() => setIsFullscreen(!isFullscreen)} 
                      className={`p-1.5 rounded ${isFullscreen ? 'bg-orange-600 text-white' : 'bg-gray-200 hover:bg-gray-300'}`}
                      title={isFullscreen ? "Exit Fullscreen" : "Fullscreen Mode"}
                    >
                      {isFullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
                
                {/* Production Mode Controls */}
                <div className="flex flex-wrap gap-1 pt-2 border-t">
                  {/* View Mode */}
                  <button
                    onClick={() => setViewMode(viewMode === VIEW_MODES.HIGH_CONTRAST ? VIEW_MODES.NORMAL : VIEW_MODES.HIGH_CONTRAST)}
                    className={`flex items-center gap-1 px-2 py-1 rounded text-[10px] transition-all ${
                      viewMode === VIEW_MODES.HIGH_CONTRAST ? 'bg-gray-800 text-white' : 'bg-gray-100 hover:bg-gray-200'
                    }`}
                    title="High Contrast Mode"
                  >
                    <Eye className="w-3 h-3" />
                    {viewMode === VIEW_MODES.HIGH_CONTRAST ? 'B/W' : 'Color'}
                  </button>
                  
                  {/* Grid Toggle */}
                  <button
                    onClick={() => setShowGrid(!showGrid)}
                    className={`flex items-center gap-1 px-2 py-1 rounded text-[10px] transition-all ${
                      showGrid ? 'bg-blue-600 text-white' : 'bg-gray-100 hover:bg-gray-200'
                    }`}
                    title="Grid Overlay"
                  >
                    <Grid3X3 className="w-3 h-3" />
                    Grid
                  </button>
                  
                  {/* Center Marks Toggle */}
                  <button
                    onClick={() => setShowCenterMarks(!showCenterMarks)}
                    className={`flex items-center gap-1 px-2 py-1 rounded text-[10px] transition-all ${
                      showCenterMarks ? 'bg-red-600 text-white' : 'bg-gray-100 hover:bg-gray-200'
                    }`}
                    title="Center Marks"
                  >
                    <Crosshair className="w-3 h-3" />
                    Centers
                  </button>
                  
                  {/* Dimension Lines Toggle */}
                  <button
                    onClick={() => setShowDimensionLines(!showDimensionLines)}
                    className={`flex items-center gap-1 px-2 py-1 rounded text-[10px] transition-all ${
                      showDimensionLines ? 'bg-green-600 text-white' : 'bg-gray-100 hover:bg-gray-200'
                    }`}
                    title="Dimension Lines"
                  >
                    <Ruler className="w-3 h-3" />
                    Dims
                  </button>
                  
                  {/* Cutout Numbers Toggle */}
                  <button
                    onClick={() => setShowCutoutNumbers(!showCutoutNumbers)}
                    className={`flex items-center gap-1 px-2 py-1 rounded text-[10px] transition-all ${
                      showCutoutNumbers ? 'bg-purple-600 text-white' : 'bg-gray-100 hover:bg-gray-200'
                    }`}
                    title="Cutout Numbers"
                  >
                    <FileText className="w-3 h-3" />
                    Labels
                  </button>
                  
                  {/* Export PDF */}
                  <button
                    onClick={exportToPDF}
                    disabled={exportingPDF || config.cutouts.length === 0}
                    className="flex items-center gap-1 px-2 py-1 rounded text-[10px] bg-orange-500 text-white hover:bg-orange-600 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                    title="Export PDF Specification"
                  >
                    {exportingPDF ? <Loader2 className="w-3 h-3 animate-spin" /> : <Download className="w-3 h-3" />}
                    PDF
                  </button>
                  
                  {/* Export STL */}
                  <button
                    onClick={() => export3DModel('stl')}
                    disabled={exporting3D}
                    className="flex items-center gap-1 px-2 py-1 rounded text-[10px] bg-blue-500 text-white hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                    title="Export 3D Model (STL)"
                  >
                    {exporting3D ? <Loader2 className="w-3 h-3 animate-spin" /> : <Download className="w-3 h-3" />}
                    STL
                  </button>
                  
                  {/* Export OBJ */}
                  <button
                    onClick={() => export3DModel('obj')}
                    disabled={exporting3D}
                    className="flex items-center gap-1 px-2 py-1 rounded text-[10px] bg-teal-500 text-white hover:bg-teal-600 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                    title="Export 3D Model (OBJ)"
                  >
                    {exporting3D ? <Loader2 className="w-3 h-3 animate-spin" /> : <Download className="w-3 h-3" />}
                    OBJ
                  </button>
                  
                  {/* Share Button */}
                  <button
                    onClick={createShareLink}
                    disabled={creatingShareLink}
                    className="flex items-center gap-1 px-2 py-1 rounded text-[10px] bg-indigo-500 text-white hover:bg-indigo-600 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                    title="Share Configuration"
                    data-testid="share-button"
                  >
                    {creatingShareLink ? <Loader2 className="w-3 h-3 animate-spin" /> : <Share2 className="w-3 h-3" />}
                    Share
                  </button>
                </div>
              </div>
              
              <div className="relative">
                <canvas
                  ref={canvasRef}
                  className={`w-full ${isFullscreen ? 'h-screen' : (isLargePreview ? 'h-[950px]' : 'h-[850px]')} transition-all duration-300 ${viewMode === VIEW_MODES.HIGH_CONTRAST ? 'bg-white' : ''}`}
                  data-testid="babylon-canvas"
                  style={{ touchAction: 'none', cursor: isMeasuring ? 'crosshair' : (isDrawingPolygon ? 'crosshair' : (isPlacementMode ? 'crosshair' : 'default')) }}
                />

                {/* Measurement mode indicator */}
                {isMeasuring && (
                  <div className="absolute top-2 left-2 bg-orange-500 text-white px-3 py-1.5 rounded-lg text-xs flex items-center gap-2">
                    <Ruler className="w-3 h-3" />
                    {currentMeasurePoint ? 'Click second point...' : 'Click first point to measure'}
                    <button 
                      onClick={toggleMeasurementMode}
                      className="ml-2 px-2 py-0.5 bg-red-600 rounded text-[10px] hover:bg-red-700"
                    >
                      Done
                    </button>
                  </div>
                )}

                {/* Measurement results panel */}
                {measurePoints.length > 0 && !isMeasuring && (
                  <div className="absolute top-2 right-2 bg-white/95 backdrop-blur rounded-lg shadow-lg p-2 max-w-[180px]">
                    <div className="flex justify-between items-center mb-1">
                      <p className="text-[10px] font-semibold text-orange-600 flex items-center gap-1">
                        <Ruler className="w-3 h-3" />
                        Measurements
                      </p>
                      <button onClick={clearMeasurements} className="text-red-500 hover:text-red-700">
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                    <div className="space-y-1 max-h-32 overflow-y-auto">
                      {measurePoints.map((m, idx) => (
                        <div key={m.id} className="text-[10px] bg-orange-50 px-2 py-1 rounded flex justify-between">
                          <span className="text-gray-600">#{idx + 1}</span>
                          <span className="font-bold text-orange-700">{m.distance} mm</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Polygon drawing mode indicator */}
                {isDrawingPolygon && (
                  <div className="absolute top-2 left-2 bg-teal-600 text-white px-3 py-1.5 rounded-lg text-xs flex items-center gap-2">
                    <Pencil className="w-3 h-3" />
                    Drawing polygon... {polygonPoints.length} points
                    <button 
                      onClick={cancelPolygonDrawing}
                      className="ml-2 px-2 py-0.5 bg-red-500 rounded text-[10px] hover:bg-red-600"
                    >
                      Cancel
                    </button>
                    {polygonPoints.length >= 3 && (
                      <button 
                        onClick={() => completePolygon(polygonPoints)}
                        className="px-2 py-0.5 bg-green-500 rounded text-[10px] hover:bg-green-600"
                      >
                        Complete
                      </button>
                    )}
                  </div>
                )}

                {/* Placement mode indicator */}
                {isPlacementMode && !isDrawingPolygon && !isMeasuring && (
                  <div className="absolute top-2 left-2 bg-blue-600 text-white px-3 py-1.5 rounded-lg text-xs flex items-center gap-2 animate-pulse">
                    <MousePointer className="w-3 h-3" />
                    Click to place {CUTOUT_SHAPES.find(s => s.id === selectedCutoutType)?.name}
                  </div>
                )}

                {/* Selected cutout badge */}
                {selectedCutoutId && !isPlacementMode && !isDrawingPolygon && !isMeasuring && (
                  <div className="absolute top-2 left-2 bg-blue-500 text-white px-2 py-1 rounded-lg text-xs flex items-center gap-1">
                    <GripVertical className="w-3 h-3" /> Editing: {CUTOUT_SHAPES.find(s => s.id === selectedCutout?.type)?.name}
                  </div>
                )}

                {/* Order items list */}
                {glassItems.length > 1 && (
                  <div className="absolute top-2 right-2 bg-white rounded-lg shadow-lg p-2 max-w-[150px]">
                    <p className="text-[10px] font-semibold text-gray-600 mb-1">Items ({glassItems.length})</p>
                    {glassItems.map((item, idx) => (
                      <div 
                        key={item.id}
                        onClick={() => setActiveItemIndex(idx)}
                        className={`p-1 rounded cursor-pointer text-[10px] ${
                          idx === activeItemIndex ? 'bg-blue-50 border border-blue-200' : 'hover:bg-gray-50'
                        }`}
                      >
                        {item.name} - ₹{(item.item_price || 0).toLocaleString()}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

          </div>
        </div>
      </div>

      {/* Share Modal with QR Code */}
      {showShareModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setShowShareModal(false)} data-testid="share-modal-overlay">
          <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full p-6" onClick={e => e.stopPropagation()} data-testid="share-modal">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-bold text-gray-800 flex items-center gap-2">
                <Share2 className="w-5 h-5 text-indigo-600" />
                Share Configuration
              </h3>
              <button onClick={() => setShowShareModal(false)} className="p-1 hover:bg-gray-100 rounded-full" data-testid="share-modal-close">
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>
            
            <div className="grid md:grid-cols-2 gap-4">
              {/* QR Code Section */}
              <div className="bg-gradient-to-br from-indigo-50 to-purple-50 rounded-xl p-4 text-center">
                <div className="bg-white p-3 rounded-lg inline-block shadow-sm mb-3">
                  <QRCodeSVG 
                    value={shareUrl} 
                    size={140}
                    level="H"
                    includeMargin={true}
                    bgColor="#ffffff"
                    fgColor="#1e1b4b"
                  />
                </div>
                <p className="text-xs font-medium text-indigo-700 flex items-center justify-center gap-1">
                  <QrCode className="w-3 h-3" />
                  Scan to view configuration
                </p>
                <p className="text-[10px] text-gray-500 mt-1">Perfect for showroom samples!</p>
                <button
                  onClick={() => {
                    const svg = document.querySelector('[data-testid="share-modal"] svg');
                    if (svg) {
                      const svgData = new XMLSerializer().serializeToString(svg);
                      const canvas = document.createElement('canvas');
                      const ctx = canvas.getContext('2d');
                      const img = new Image();
                      img.onload = () => {
                        canvas.width = img.width;
                        canvas.height = img.height;
                        ctx.fillStyle = 'white';
                        ctx.fillRect(0, 0, canvas.width, canvas.height);
                        ctx.drawImage(img, 0, 0);
                        const link = document.createElement('a');
                        link.download = `glass_config_qr_${config.width_mm}x${config.height_mm}.png`;
                        link.href = canvas.toDataURL('image/png');
                        link.click();
                      };
                      img.src = 'data:image/svg+xml;base64,' + btoa(svgData);
                    }
                    toast.success('QR Code downloaded!');
                  }}
                  className="mt-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-medium rounded-lg flex items-center gap-1 mx-auto"
                >
                  <Download className="w-3 h-3" />
                  Download QR
                </button>
              </div>
              
              {/* Share Options */}
              <div className="space-y-3">
                <p className="text-sm text-gray-600">
                  Share via link, WhatsApp, or Email. Recipients can view and order!
                </p>
                
                {/* Link Preview */}
                <div className="bg-gray-50 rounded-lg p-2">
                  <p className="text-[10px] text-gray-500 mb-1">Shareable Link (7 days)</p>
                  <div className="flex items-center gap-1">
                    <input
                      type="text"
                      value={shareUrl}
                      readOnly
                      className="flex-1 text-xs bg-white border rounded px-2 py-1 truncate"
                      data-testid="share-url-input"
                    />
                    <button
                      onClick={copyShareLink}
                      className="px-2 py-1 bg-gray-200 hover:bg-gray-300 rounded text-xs font-medium"
                      data-testid="copy-link-button"
                    >
                      Copy
                    </button>
                  </div>
                </div>
                
                <button
                  onClick={shareViaWhatsApp}
                  className="w-full flex items-center justify-center gap-2 px-4 py-2.5 bg-green-500 hover:bg-green-600 text-white rounded-lg font-medium transition-colors text-sm"
                  data-testid="share-whatsapp-button"
                >
                  <MessageCircle className="w-4 h-4" />
                  WhatsApp
                </button>
                
                <button
                  onClick={shareViaEmail}
                  className="w-full flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-500 hover:bg-blue-600 text-white rounded-lg font-medium transition-colors text-sm"
                  data-testid="share-email-button"
                >
                  <Mail className="w-4 h-4" />
                  Email
                </button>
              </div>
            </div>
            
            <p className="text-xs text-gray-400 mt-4 text-center border-t pt-3" data-testid="share-config-summary">
              {config.width_mm}×{config.height_mm}mm • {config.thickness_mm}mm {config.glass_type} • {config.cutouts.length} cutouts
            </p>
          </div>
        </div>
      )}
    </div>
  );
};

export default GlassConfigurator3D;
