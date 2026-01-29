/**
 * Manufacturing-grade shape generator for CNC cutting
 * All shapes use normalized coordinates (0-1 range) for precision
 * Shapes are mathematically precise, centered, and uniformly scalable
 */

/**
 * Generate heart shape points (normalized 0-1 range)
 * Formula: parametric equation of a heart curve
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generateHeartPoints(resolution = 200) {
  const points = [];
  
  for (let i = 0; i <= resolution; i++) {
    const t = (i / resolution) * Math.PI * 2;
    // Parametric equations for heart shape (upright orientation - NO negative Y)
    // x = 16sin³(t), y = 13cos(t) - 5cos(2t) - 2cos(3t) - cos(4t)
    const x = 16 * Math.pow(Math.sin(t), 3);
    const y = 13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t);
    points.push({ x, y });
  }
  
  // Calculate bounding box to normalize coordinates
  let minX = points[0].x, maxX = points[0].x;
  let minY = points[0].y, maxY = points[0].y;
  
  points.forEach(p => {
    minX = Math.min(minX, p.x);
    maxX = Math.max(maxX, p.x);
    minY = Math.min(minY, p.y);
    maxY = Math.max(maxY, p.y);
  });
  
  const width = maxX - minX;
  const height = maxY - minY;
  
  // Normalize to [-0.5, 0.5] range and center
  return points.map(p => ({
    x: ((p.x - minX) / width) - 0.5,
    y: ((p.y - minY) / height) - 0.5
  }));
}

/**
 * Generate star shape points (normalized 0-1 range)
 * 5-pointed star with correct proportions
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generateStarPoints() {
  const points = [];
  const outerRadius = 0.5;
  const innerRadius = 0.5 * 0.38; // Golden ratio proportion
  
  for (let i = 0; i < 10; i++) {
    const angle = (i * Math.PI / 5) - Math.PI / 2;
    const radius = i % 2 === 0 ? outerRadius : innerRadius;
    points.push({
      x: Math.cos(angle) * radius,
      y: Math.sin(angle) * radius
    });
  }
  
  return points;
}

/**
 * Generate diamond shape points (normalized 0-1 range)
 * Rotated square with proper aspect ratio
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generateDiamondPoints() {
  const size = 0.5;
  return [
    { x: 0, y: size },      // top
    { x: size, y: 0 },      // right
    { x: 0, y: -size },     // bottom
    { x: -size, y: 0 }      // left
  ];
}

/**
 * Generate triangle shape points (normalized 0-1 range)
 * Equilateral triangle
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generateTrianglePoints() {
  const size = 0.5;
  const h = size * Math.sqrt(3) / 2;
  return [
    { x: 0, y: h },           // top
    { x: -size, y: -h / 2 },  // bottom left
    { x: size, y: -h / 2 }    // bottom right
  ];
}

/**
 * Generate pentagon shape points (normalized 0-1 range)
 * Regular pentagon
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generatePentagonPoints() {
  const points = [];
  const radius = 0.5;
  
  for (let i = 0; i < 5; i++) {
    const angle = (i * 2 * Math.PI / 5) - Math.PI / 2;
    points.push({
      x: Math.cos(angle) * radius,
      y: Math.sin(angle) * radius
    });
  }
  
  return points;
}

/**
 * Generate hexagon shape points (normalized 0-1 range)
 * Regular hexagon
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generateHexagonPoints() {
  const points = [];
  const radius = 0.5;
  
  for (let i = 0; i < 6; i++) {
    const angle = i * Math.PI / 3;
    points.push({
      x: Math.cos(angle) * radius,
      y: Math.sin(angle) * radius
    });
  }
  
  return points;
}

/**
 * Generate octagon shape points (normalized 0-1 range)
 * Regular octagon
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generateOctagonPoints() {
  const points = [];
  const radius = 0.5;
  
  for (let i = 0; i < 8; i++) {
    const angle = i * Math.PI / 4;
    points.push({
      x: Math.cos(angle) * radius,
      y: Math.sin(angle) * radius
    });
  }
  
  return points;
}

/**
 * Generate circle shape points (normalized 0-1 range)
 * Perfect circle discretized to polygon
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generateCirclePoints(resolution = 64) {
  const points = [];
  const radius = 0.5;
  
  for (let i = 0; i < resolution; i++) {
    const angle = (i / resolution) * Math.PI * 2;
    points.push({
      x: Math.cos(angle) * radius,
      y: Math.sin(angle) * radius
    });
  }
  
  return points;
}

/**
 * Generate rectangle points (normalized 0-1 range)
 * Axis-aligned rectangle
 * aspectRatio: width / height
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generateRectanglePoints(aspectRatio = 1.0) {
  let w = 0.5;
  let h = 0.5;
  
  // Maintain aspect ratio
  if (aspectRatio > 1) {
    h = w / aspectRatio;
  } else {
    w = h * aspectRatio;
  }
  
  return [
    { x: -w, y: -h },  // bottom-left
    { x: w, y: -h },   // bottom-right
    { x: w, y: h },    // top-right
    { x: -w, y: h }    // top-left
  ];
}

/**
 * Generate oval/ellipse shape points (normalized 0-1 range)
 * Discretized ellipse
 * aspectRatio: width / height
 * Returns: Array of {x, y} points normalized to [-0.5, 0.5]
 */
export function generateOvalPoints(aspectRatio = 1.5, resolution = 64) {
  const points = [];
  let radiusX = 0.5;
  let radiusY = 0.5;
  
  // Maintain aspect ratio
  if (aspectRatio > 1) {
    radiusY = radiusX / aspectRatio;
  } else {
    radiusX = radiusY * aspectRatio;
  }
  
  for (let i = 0; i < resolution; i++) {
    const angle = (i / resolution) * Math.PI * 2;
    points.push({
      x: Math.cos(angle) * radiusX,
      y: Math.sin(angle) * radiusY
    });
  }
  
  return points;
}

/**
 * Scale normalized points by dimension (respects aspect ratio)
 * points: Array of {x, y} in [-0.5, 0.5] range
 * width: desired width in units
 * height: desired height in units
 * Returns: Array of scaled {x, y} points
 */
export function scalePoints(points, width, height) {
  return points.map(p => ({
    x: p.x * width,
    y: p.y * height
  }));
}

/**
 * Translate points to a specific position
 * points: Array of {x, y}
 * offsetX: x translation
 * offsetY: y translation
 * Returns: Array of translated {x, y} points
 */
export function translatePoints(points, offsetX, offsetY) {
  return points.map(p => ({
    x: p.x + offsetX,
    y: p.y + offsetY
  }));
}

/**
 * Rotate points around origin (0, 0)
 * points: Array of {x, y}
 * angleRad: rotation angle in radians
 * Returns: Array of rotated {x, y} points
 */
export function rotatePoints(points, angleRad) {
  const cos = Math.cos(angleRad);
  const sin = Math.sin(angleRad);
  
  return points.map(p => ({
    x: p.x * cos - p.y * sin,
    y: p.x * sin + p.y * cos
  }));
}

/**
 * Convert normalized points to Canvas Path2D
 * points: Array of {x, y}
 * Returns: Path2D object
 */
export function pointsToCanvasPath(points) {
  if (!points || points.length === 0) return new Path2D();
  
  const path = new Path2D();
  path.moveTo(points[0].x, points[0].y);
  
  for (let i = 1; i < points.length; i++) {
    path.lineTo(points[i].x, points[i].y);
  }
  
  path.closePath();
  return path;
}

/**
 * Convert normalized points to SVG path string
 * points: Array of {x, y}
 * scale: scale factor for SVG coordinates
 * Returns: SVG path data string
 */
export function pointsToSVGPath(points, scale = 100) {
  if (!points || points.length === 0) return '';
  
  let pathData = `M ${points[0].x * scale} ${points[0].y * scale}`;
  
  for (let i = 1; i < points.length; i++) {
    pathData += ` L ${points[i].x * scale} ${points[i].y * scale}`;
  }
  
  pathData += ' Z';
  return pathData;
}

/**
 * Convert normalized points to Babylon.js Vector2 array
 * points: Array of {x, y}
 * Returns: Array of BABYLON.Vector2
 */
export function pointsToBabylonVector2(points) {
  if (typeof BABYLON === 'undefined') return [];
  
  return points.map(p => new BABYLON.Vector2(p.x, p.y));
}

/**
 * Get all shape generators as a map for easy access
 */
export const shapeGenerators = {
  'HR': generateHeartPoints,
  'ST': generateStarPoints,
  'DM': generateDiamondPoints,
  'T': generateTrianglePoints,
  'PT': generatePentagonPoints,
  'HX': generateHexagonPoints,
  'OC': generateOctagonPoints,
  'SH': generateCirclePoints,
  'OV': generateOvalPoints,
  'R': (aspectRatio) => generateRectanglePoints(aspectRatio)
};

export default {
  generateHeartPoints,
  generateStarPoints,
  generateDiamondPoints,
  generateTrianglePoints,
  generatePentagonPoints,
  generateHexagonPoints,
  generateOctagonPoints,
  generateCirclePoints,
  generateRectanglePoints,
  generateOvalPoints,
  scalePoints,
  translatePoints,
  rotatePoints,
  pointsToCanvasPath,
  pointsToSVGPath,
  pointsToBabylonVector2,
  shapeGenerators
};
