from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Literal
import numpy as np
from io import BytesIO
import base64
from datetime import datetime, timezone
import os

# Configure trimesh to use system OpenSCAD
os.environ['PATH'] = '/usr/bin:' + os.environ.get('PATH', '')

router = APIRouter(prefix="/glass-3d", tags=["3D Glass Modeling"])

# =============== MODELS ===============

class CutoutSpec(BaseModel):
    """Specification for a hole or cutout in glass"""
    model_config = ConfigDict(extra="ignore")
    shape: Literal["circle", "square", "rectangle", "triangle", "hexagon", "heart"]
    # Position from bottom-left corner in mm
    x: float
    y: float
    # Dimensions
    diameter: Optional[float] = None  # For circles
    width: Optional[float] = None  # For rectangles/squares
    height: Optional[float] = None  # For rectangles
    side: Optional[float] = None  # For regular polygons

class Glass3DRequest(BaseModel):
    """Request to generate 3D glass model"""
    model_config = ConfigDict(extra="ignore")
    # Glass dimensions in mm
    width: float = Field(gt=0, description="Glass width in mm")
    height: float = Field(gt=0, description="Glass height in mm")
    thickness: float = Field(gt=0, description="Glass thickness in mm")
    # Cutouts
    cutouts: List[CutoutSpec] = Field(default_factory=list)
    # Export format
    export_format: Literal["stl", "obj", "ply", "json"] = "stl"

class Glass3DResponse(BaseModel):
    """Response with 3D model data"""
    model_config = ConfigDict(extra="ignore")
    success: bool
    format: str
    file_data: str  # Base64 encoded
    volume_mm3: float
    surface_area_mm2: float
    weight_kg: Optional[float] = None  # Calculated based on glass density
    metadata: dict

# =============== 3D GENERATION FUNCTIONS ===============

def create_circle_mesh(center_x, center_y, center_z, diameter, thickness):
    """Create a cylindrical hole mesh"""
    try:
        import pyvista as pv
        radius = diameter / 2
        # Create cylinder for boolean subtraction
        cylinder = pv.Cylinder(
            center=(center_x, center_y, center_z),
            direction=(0, 0, 1),
            radius=radius,
            height=thickness * 1.5  # Slightly larger to ensure clean cut
        )
        return cylinder
    except ImportError:
        raise HTTPException(status_code=500, detail="PyVista not installed")

def create_rectangle_mesh(center_x, center_y, center_z, width, height, thickness):
    """Create a rectangular cutout mesh"""
    try:
        import pyvista as pv
        # Create a box for boolean subtraction
        box = pv.Cube(
            center=(center_x, center_y, center_z),
            x_length=width,
            y_length=height,
            z_length=thickness * 1.5
        )
        return box
    except ImportError:
        raise HTTPException(status_code=500, detail="PyVista not installed")

def create_polygon_mesh(center_x, center_y, center_z, num_sides, side_length, thickness):
    """Create a regular polygon cutout"""
    try:
        import pyvista as pv
        # Calculate radius for regular polygon
        radius = side_length / (2 * np.sin(np.pi / num_sides))
        
        # Create polygon points
        angles = np.linspace(0, 2 * np.pi, num_sides, endpoint=False)
        x_points = center_x + radius * np.cos(angles)
        y_points = center_y + radius * np.sin(angles)
        
        # Create bottom face
        points_bottom = np.column_stack([x_points, y_points, np.full(num_sides, center_z - thickness/2)])
        # Create top face
        points_top = np.column_stack([x_points, y_points, np.full(num_sides, center_z + thickness/2)])
        
        # Combine points
        points = np.vstack([points_bottom, points_top])
        
        # Create faces (triangulate polygon)
        from scipy.spatial import Delaunay
        
        # Bottom face
        tri = Delaunay(points_bottom[:, :2])
        bottom_faces = [[3] + list(face) for face in tri.simplices]
        
        # Top face (reversed winding)
        top_faces = [[3] + [f + num_sides for f in face][::-1] for face in tri.simplices]
        
        # Side faces
        side_faces = []
        for i in range(num_sides):
            next_i = (i + 1) % num_sides
            # Two triangles per side
            side_faces.append([3, i, next_i, i + num_sides])
            side_faces.append([3, next_i, next_i + num_sides, i + num_sides])
        
        faces = bottom_faces + top_faces + side_faces
        mesh = pv.PolyData(points, faces)
        
        return mesh
    except ImportError:
        raise HTTPException(status_code=500, detail="PyVista or SciPy not installed")

def create_heart_mesh(center_x, center_y, center_z, size, thickness):
    """Create a heart-shaped cutout"""
    try:
        import pyvista as pv
        
        # Heart curve parametric equations
        t = np.linspace(0, 2 * np.pi, 100)
        scale = size / 2
        x = scale * 16 * np.sin(t)**3
        y = scale * (13 * np.cos(t) - 5 * np.cos(2*t) - 2 * np.cos(3*t) - np.cos(4*t))
        
        # Offset to center
        x_points = center_x + x
        y_points = center_y + y
        
        # Create 3D extrusion
        points_bottom = np.column_stack([x_points, y_points, np.full(len(t), center_z - thickness/2)])
        points_top = np.column_stack([x_points, y_points, np.full(len(t), center_z + thickness/2)])
        
        points = np.vstack([points_bottom, points_top])
        
        # Create mesh from points
        from scipy.spatial import Delaunay
        tri = Delaunay(points_bottom[:, :2])
        
        n = len(t)
        bottom_faces = [[3] + list(face) for face in tri.simplices]
        top_faces = [[3] + [f + n for f in face][::-1] for face in tri.simplices]
        
        # Side faces
        side_faces = []
        for i in range(n):
            next_i = (i + 1) % n
            side_faces.append([3, i, next_i, i + n])
            side_faces.append([3, next_i, next_i + n, i + n])
        
        faces = bottom_faces + top_faces + side_faces
        mesh = pv.PolyData(points, faces)
        
        return mesh
    except ImportError:
        raise HTTPException(status_code=500, detail="PyVista or SciPy not installed")

# =============== API ENDPOINTS ===============

@router.post("/generate", response_model=Glass3DResponse)
async def generate_glass_3d_model(request: Glass3DRequest):
    """
    Generate a 3D glass model with cutouts and export to specified format
    
    This endpoint creates a parametric 3D model of glass with holes/cutouts,
    calculates physical properties, and exports to STL/OBJ/PLY formats.
    """
    try:
        import pyvista as pv
        
        # Create base glass sheet
        glass = pv.Cube(
            center=(request.width/2, request.height/2, request.thickness/2),
            x_length=request.width,
            y_length=request.height,
            z_length=request.thickness
        )
        
        # Clean and triangulate before boolean ops
        glass = glass.clean().triangulate()
        
        # Apply cutouts using boolean operations
        for cutout in request.cutouts:
            cutout_mesh = None
            center_z = request.thickness / 2
            
            if cutout.shape == "circle" and cutout.diameter:
                # Create cylinder for circular cutout
                radius = cutout.diameter / 2
                cutout_mesh = pv.Cylinder(
                    center=(cutout.x, cutout.y, center_z),
                    direction=(0, 0, 1),
                    radius=radius,
                    height=request.thickness * 1.2,  # Slightly taller
                    resolution=32
                )
            
            elif cutout.shape in ["square", "rectangle"] and cutout.width:
                height = cutout.height or cutout.width
                cutout_mesh = pv.Cube(
                    center=(cutout.x, cutout.y, center_z),
                    x_length=cutout.width,
                    y_length=height,
                    z_length=request.thickness * 1.2
                )
            
            # Perform boolean subtraction
            if cutout_mesh is not None:
                cutout_mesh = cutout_mesh.clean().triangulate()
                try:
                    glass = glass.boolean_difference(cutout_mesh, tolerance=0.0001)
                    glass = glass.clean().triangulate()
                except Exception as e:
                    # Log but continue if boolean fails for one cutout
                    import logging
                    logging.error(f"Boolean operation failed for cutout: {e}")
                    continue
        
        # Calculate physical properties using VTK  
        # Volume calculation
        volume_mm3 = 0.0
        surface_area_mm2 = 0.0
        
        try:
            from vtkmodules.vtkFiltersCore import vtkMassProperties
            mass_props = vtkMassProperties()
            mass_props.SetInputData(glass)
            volume_mm3 = mass_props.GetVolume()
            surface_area_mm2 = mass_props.GetSurfaceArea()
        except Exception as e:
            # Fallback: approximate from mesh dimensions
            import logging
            logging.warning(f"Mass properties calculation failed: {e}")
            volume_mm3 = request.width * request.height * request.thickness
            surface_area_mm2 = 2 * (request.width * request.height + 
                                      request.width * request.thickness + 
                                      request.height * request.thickness)
        
        # Calculate weight (glass density ~2.5 g/cm³ = 0.0025 kg/mm³)
        glass_density_kg_per_mm3 = 0.0000025
        weight_kg = volume_mm3 * glass_density_kg_per_mm3
        
        # Export to requested format
        buffer = BytesIO()
        
        if request.export_format == "stl":
            # Save to temporary file then read back
            import tempfile
            with tempfile.NamedTemporaryFile(suffix='.stl', delete=False) as tmp:
                glass.save(tmp.name, binary=True)
                tmp_path = tmp.name
            with open(tmp_path, 'rb') as f:
                buffer.write(f.read())
            import os
            os.unlink(tmp_path)
        elif request.export_format == "obj":
            import tempfile
            with tempfile.NamedTemporaryFile(suffix='.obj', delete=False) as tmp:
                pv.save_meshio(tmp.name, glass, file_format='obj')
                tmp_path = tmp.name
            with open(tmp_path, 'rb') as f:
                buffer.write(f.read())
            import os
            os.unlink(tmp_path)
        elif request.export_format == "obj":
            pv.save_meshio(buffer, glass, file_format='obj')
        elif request.export_format == "ply":
            glass.save(buffer, binary=False)
        else:  # json
            # Export as JSON with vertices and faces
            vertices = glass.points.tolist()
            faces = glass.faces.reshape(-1, 4)[:, 1:].tolist()  # Remove face size prefix
            json_data = {
                "vertices": vertices,
                "faces": faces,
                "volume_mm3": float(volume_mm3),
                "surface_area_mm2": float(surface_area_mm2)
            }
            import json
            buffer.write(json.dumps(json_data).encode())
        
        buffer.seek(0)
        file_data_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
        
        return Glass3DResponse(
            success=True,
            format=request.export_format,
            file_data=file_data_base64,
            volume_mm3=float(volume_mm3),
            surface_area_mm2=float(surface_area_mm2),
            weight_kg=float(weight_kg),
            metadata={
                "width_mm": request.width,
                "height_mm": request.height,
                "thickness_mm": request.thickness,
                "num_cutouts": len(request.cutouts),
                "generated_at": datetime.now(timezone.utc).isoformat()
            }
        )
        
    except ImportError as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Required 3D library not installed: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generating 3D model: {str(e)}"
        )

@router.get("/formats")
async def get_supported_formats():
    """Get list of supported export formats"""
    return {
        "formats": [
            {
                "id": "stl",
                "name": "STL",
                "description": "Standard Tessellation Language - for 3D printing and CNC",
                "mime_type": "model/stl",
                "extension": ".stl"
            },
            {
                "id": "obj",
                "name": "Wavefront OBJ",
                "description": "Common 3D format for CAD software",
                "mime_type": "model/obj",
                "extension": ".obj"
            },
            {
                "id": "ply",
                "name": "PLY",
                "description": "Polygon File Format",
                "mime_type": "model/ply",
                "extension": ".ply"
            },
            {
                "id": "json",
                "name": "JSON",
                "description": "Vertices and faces as JSON",
                "mime_type": "application/json",
                "extension": ".json"
            }
        ]
    }
