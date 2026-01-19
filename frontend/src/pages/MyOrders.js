import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Package, Eye, Download, Calendar, DollarSign, Loader2 } from 'lucide-react';
import { Button } from '../components/ui/button';
import { toast } from 'sonner';

const API_URL = process.env.REACT_APP_BACKEND_URL;

const MyOrders = () => {
  const navigate = useNavigate();
  const { currentUser } = useAuth();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [showDesignViewer, setShowDesignViewer] = useState(false);

  useEffect(() => {
    if (!currentUser) {
      navigate('/login');
      return;
    }
    fetchOrders();
  }, [currentUser, navigate]);

  const fetchOrders = async () => {
    try {
      const response = await fetch(`${API_URL}/api/erp/orders/my-orders?include_designs=true`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });

      if (response.ok) {
        const data = await response.json();
        setOrders(data);
      } else {
        toast.error('Failed to fetch orders');
      }
    } catch (error) {
      console.error('Error fetching orders:', error);
      toast.error('Error loading orders');
    } finally {
      setLoading(false);
    }
  };

  const viewDesign = (order) => {
    if (order.glass_config) {
      setSelectedOrder(order);
      setShowDesignViewer(true);
    } else {
      toast.info('No 3D design available for this order');
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      'pending': 'bg-yellow-100 text-yellow-800',
      'processing': 'bg-blue-100 text-blue-800',
      'completed': 'bg-green-100 text-green-800',
      'cancelled': 'bg-red-100 text-red-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900">My Orders</h1>
          <p className="text-gray-600 mt-1">View your order history and 3D glass designs</p>
        </div>

        {orders.length === 0 ? (
          <div className="bg-white rounded-lg shadow p-12 text-center">
            <Package className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 mb-2">No orders yet</h3>
            <p className="text-gray-600 mb-6">Start designing your custom glass!</p>
            <Button onClick={() => navigate('/customize')}>
              Create New Design
            </Button>
          </div>
        ) : (
          <div className="space-y-4">
            {orders.map((order) => (
              <div key={order.id} className="bg-white rounded-lg shadow hover:shadow-md transition-shadow">
                <div className="p-6">
                  <div className="flex justify-between items-start mb-4">
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900">
                        Order #{order.order_number}
                      </h3>
                      <div className="flex items-center gap-2 mt-1 text-sm text-gray-600">
                        <Calendar className="w-4 h-4" />
                        {new Date(order.created_at).toLocaleDateString('en-US', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric'
                        })}
                      </div>
                    </div>
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(order.status)}`}>
                      {order.status.toUpperCase()}
                    </span>
                  </div>

                  {/* Glass Config Details */}
                  {order.glass_config && (
                    <div className="mb-4 p-3 bg-blue-50 rounded-lg">
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                        <div>
                          <span className="text-gray-600">Dimensions:</span>
                          <p className="font-semibold">{order.glass_config.width_mm}×{order.glass_config.height_mm}mm</p>
                        </div>
                        <div>
                          <span className="text-gray-600">Thickness:</span>
                          <p className="font-semibold">{order.glass_config.thickness_mm}mm</p>
                        </div>
                        <div>
                          <span className="text-gray-600">Type:</span>
                          <p className="font-semibold">{order.glass_config.glass_type}</p>
                        </div>
                        <div>
                          <span className="text-gray-600">Cutouts:</span>
                          <p className="font-semibold">{order.glass_config.cutouts?.length || 0} shapes</p>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Order Details */}
                  <div className="flex items-center gap-4 mb-4 text-sm">
                    <div className="flex items-center gap-1">
                      <Package className="w-4 h-4 text-gray-500" />
                      <span>Qty: {order.quantity}</span>
                    </div>
                    {order.total_amount > 0 && (
                      <div className="flex items-center gap-1">
                        <DollarSign className="w-4 h-4 text-gray-500" />
                        <span>₹{order.total_amount.toLocaleString()}</span>
                      </div>
                    )}
                    <span className="px-2 py-1 bg-gray-100 rounded text-xs">
                      Payment: {order.payment_status}
                    </span>
                  </div>

                  {order.notes && (
                    <p className="text-sm text-gray-600 mb-4">
                      <span className="font-medium">Notes:</span> {order.notes}
                    </p>
                  )}

                  {/* Actions */}
                  <div className="flex gap-2">
                    {order.glass_config && (
                      <Button
                        onClick={() => viewDesign(order)}
                        variant="outline"
                        size="sm"
                        className="flex items-center gap-2"
                      >
                        <Eye className="w-4 h-4" />
                        View 3D Design
                      </Button>
                    )}
                    <Button
                      onClick={() => navigate(`/track/${order.order_number}`)}
                      variant="outline"
                      size="sm"
                    >
                      Track Order
                    </Button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Design Viewer Modal */}
        {showDesignViewer && selectedOrder && (
          <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-lg max-w-4xl w-full max-h-[90vh] overflow-auto">
              <div className="p-6">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h2 className="text-2xl font-bold text-gray-900">
                      3D Glass Design
                    </h2>
                    <p className="text-gray-600">Order #{selectedOrder.order_number}</p>
                  </div>
                  <button
                    onClick={() => setShowDesignViewer(false)}
                    className="text-gray-500 hover:text-gray-700"
                  >
                    ✕
                  </button>
                </div>

                {/* Design Details */}
                <div className="bg-gray-50 rounded-lg p-4 mb-4">
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                    <div>
                      <span className="text-sm text-gray-600">Width:</span>
                      <p className="font-semibold">{selectedOrder.glass_config.width_mm}mm</p>
                    </div>
                    <div>
                      <span className="text-sm text-gray-600">Height:</span>
                      <p className="font-semibold">{selectedOrder.glass_config.height_mm}mm</p>
                    </div>
                    <div>
                      <span className="text-sm text-gray-600">Thickness:</span>
                      <p className="font-semibold">{selectedOrder.glass_config.thickness_mm}mm</p>
                    </div>
                    <div>
                      <span className="text-sm text-gray-600">Type:</span>
                      <p className="font-semibold">{selectedOrder.glass_config.glass_type}</p>
                    </div>
                    <div>
                      <span className="text-sm text-gray-600">Color:</span>
                      <p className="font-semibold">{selectedOrder.glass_config.color_name}</p>
                    </div>
                    <div>
                      <span className="text-sm text-gray-600">Application:</span>
                      <p className="font-semibold">{selectedOrder.glass_config.application || 'N/A'}</p>
                    </div>
                  </div>
                </div>

                {/* Cutouts List */}
                <div className="mb-4">
                  <h3 className="text-lg font-semibold mb-2">Cutouts ({selectedOrder.glass_config.cutouts?.length || 0})</h3>
                  <div className="space-y-2">
                    {selectedOrder.glass_config.cutouts?.map((cutout, idx) => (
                      <div key={idx} className="bg-white border rounded-lg p-3 text-sm">
                        <div className="flex justify-between">
                          <span className="font-medium">#{idx + 1} - {cutout.type}</span>
                          <span className="text-gray-600">
                            {cutout.diameter ? `Ø${cutout.diameter}mm` : `${cutout.width}×${cutout.height}mm`}
                          </span>
                        </div>
                        <div className="text-gray-600 text-xs mt-1">
                          Position: ({Math.round(cutout.x)}, {Math.round(cutout.y)})
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex gap-2">
                  <Button
                    onClick={() => {
                      navigate(`/customize?load=${selectedOrder.glass_config_id}`);
                    }}
                    className="flex-1"
                  >
                    Edit in 3D Canvas
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => setShowDesignViewer(false)}
                  >
                    Close
                  </Button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default MyOrders;
