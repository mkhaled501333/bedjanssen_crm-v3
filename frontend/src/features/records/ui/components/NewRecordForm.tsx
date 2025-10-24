'use client';

import React, { useState, useEffect, useRef } from 'react';
import {
  getGovernoratesWithCities,
  getCallCategories,
  getTicketCategories,
  getRequestReasons,
  getProducts,
  getCompanies
} from '../../../masterdata/api';
import {
  createCustomerWithCall,
  createCustomerWithTicket
} from '../../../customerdata/api';
import Select from 'react-select';
import type { StylesConfig, CSSObjectWithLabel } from 'react-select';
import type { Product } from '../../../masterdata/types';
import { getCurrentUserCompanyId, getCurrentUserId } from '../../../../shared/utils/auth';

interface NewRecordFormProps {
  initialQuery?: string;
  onSubmit?: (customerId: unknown, customerName: string) => void;
  onCancel?: () => void;
  onFormChange?: (formData: Record<string, unknown>) => void; // Form change handler
  initialFormData?: Record<string, unknown> | null;
  onTabNameUpdate?: (tabName: string) => void; // For updating tab name when customer name changes
  isActive?: boolean; // Whether this form is currently visible/active
  tabId?: string; // Unique identifier for this tab instance
}

interface Governorate {
  id: number;
  name: string;
  cities?: { id: number; name: string }[];
}

interface DropdownOption {
  id: number;
  name: string;
}

interface FormData {
  // Customer data
  name: string;
  phone: string;
  governorateId: string;
  cityId: string;
  address: string;
  notes: string;

  // Request type
  requestType: 'maintenance' | 'call';

  // Maintenance fields
  productId: string;
  brandId: string;
  quantity: string;
  length: string; // طول
  width: string;  // عرض
  height: string; // ارتفاع
  purchaseDate: string;
  purchasePlace: string;
  requestReasonId: string;
  requestReasonDetail: string;

  // Call fields (for both maintenance and call types)
  callType: 'incoming' | 'outgoing';
  callReasonId: string;
  callResult: string;
  callNotes: string; // New field for call notes
  callDurationMinutes: string;
  callDurationSeconds: string;
}

// Helper to map options for React Select
const toSelectOption = (item: { id: number; name: string }) => ({ value: item.id, label: item.name });

// Add a simple toast component
function Toast({ message, onClose }: { message: string, onClose: () => void }) {
  useEffect(() => {
    const timer = setTimeout(onClose, 2500);
    return () => clearTimeout(timer);
  }, [onClose]);
  return (
    <div style={{
      position: 'fixed',
      top: 24,
      right: 24,
      background: '#323232',
      color: 'white',
      padding: '16px 32px',
      borderRadius: 8,
      fontSize: 18,
      zIndex: 99999,
      boxShadow: '0 2px 8px rgba(0,0,0,0.15)'
    }}>
      {message}
    </div>
  );
}


export function NewRecordForm({ initialQuery = '', onSubmit, onFormChange, initialFormData, onTabNameUpdate, isActive = true, tabId = 'default' }: NewRecordFormProps): JSX.Element {
  // Check if initialQuery is a phone number (contains only digits, spaces, +, -, (, ))
  const isPhoneNumber = /^[\d\s\+\-\(\)]+$/.test(initialQuery.trim());
  
  const [formData, setFormData] = useState<FormData>(() => {
    // Initialize with initialFormData if available, otherwise use default values
    if (initialFormData) {
      return initialFormData as unknown as FormData;
    }
    const defaultData: FormData = {
      name: isPhoneNumber ? '' : initialQuery,
      phone: isPhoneNumber ? initialQuery : '',
      governorateId: '',
      cityId: '',
      address: '',
      notes: '',
      requestType: 'call' as const,
      productId: '',
      brandId: '',
      quantity: '',
      length: '',
      width: '',
      height: '',
      purchaseDate: '',
      purchasePlace: '',
      requestReasonId: '',
      requestReasonDetail: '',
      callType: 'incoming' as const,
      callReasonId: '',
      callResult: '',
      callNotes: '', // New field
      callDurationMinutes: '',
      callDurationSeconds: '',
    };
    return defaultData;
  });

  const [governorates, setGovernorates] = useState<Governorate[]>([]);
  const [cities, setCities] = useState<DropdownOption[]>([]);
  const [callCategories, setCallCategories] = useState<DropdownOption[]>([]);
  const [ticketCategories, setTicketCategories] = useState<DropdownOption[]>([]);
  const [requestReasons, setRequestReasons] = useState<DropdownOption[]>([]);
  const [products, setProducts] = useState<Product[]>([]); // Store full products array
  const [companies, setCompanies] = useState<DropdownOption[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [hasChanges, setHasChanges] = useState(!!initialFormData);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [toast, setToast] = useState<string | null>(null);
  
  // Ref to track the last form data we sent to parent to prevent infinite loops
  const lastFormDataRef = useRef<Record<string, unknown> | null>(null);
  const lastTabNameRef = useRef<string>('');

  // Debug: Monitor callType changes (only log when callType actually changes)
  useEffect(() => {
    // Only log when callType changes and form is active to reduce noise
    // Commented out for better performance
    // if (formData.callType && isActive) {
    //   console.log('🔄 Call type changed to:', formData.callType);
    // }
  }, [formData.callType, isActive]);


  // Track form changes and notify parent with debounce (only when active)
  useEffect(() => {
    if (onFormChange && hasChanges && isActive) {
      // Only notify parent if form data has actually changed
      const formDataString = JSON.stringify(formData);
      const lastFormDataString = JSON.stringify(lastFormDataRef.current);
      
      if (formDataString !== lastFormDataString) {
        lastFormDataRef.current = formData as unknown as Record<string, unknown>;
        
        // Debounce the form change notification with longer delay for better performance
        const timeoutId = setTimeout(() => {
          onFormChange(formData as unknown as Record<string, unknown>);
        }, 1000);
        
        return () => clearTimeout(timeoutId);
      }
    }
  }, [formData, hasChanges, onFormChange, isActive]);

  // Update tab name when customer name changes with debounce (only when active)
  useEffect(() => {
    if (onTabNameUpdate && formData.name && formData.name.trim() && isActive) {
      const tabName = `New Record: ${formData.name.substring(0, 20)}${formData.name.length > 20 ? '...' : ''}`;
      
      // Only update if the tab name has actually changed
      if (tabName !== lastTabNameRef.current) {
        lastTabNameRef.current = tabName;
        
        // Debounce the tab name update
        const timeoutId = setTimeout(() => {
          onTabNameUpdate(tabName);
        }, 1000);
        
        return () => clearTimeout(timeoutId);
      }
    }
  }, [formData.name, onTabNameUpdate, isActive]);

  // Load dropdown data
  useEffect(() => {
    const loadData = async () => {
      try {
        const [
          governoratesData,
          callCategoriesData,
          ticketCategoriesData,
          requestReasonsData,
          productsData,
          companiesData
        ] = await Promise.all([
          getGovernoratesWithCities(),
          getCallCategories(),
          getTicketCategories(),
          getRequestReasons(),
          getProducts(),
          getCompanies()
        ]);

        // Handle different API response formats
        const governorates = Array.isArray(governoratesData) ? governoratesData : ((governoratesData as unknown as { data: Governorate[] })?.data || []);
        const callCategories = Array.isArray(callCategoriesData) ? callCategoriesData : ((callCategoriesData as unknown as { data: DropdownOption[] })?.data || []);
        const ticketCategories = Array.isArray(ticketCategoriesData) ? ticketCategoriesData : ((ticketCategoriesData as unknown as { data: DropdownOption[] })?.data || []);
        const requestReasons = Array.isArray(requestReasonsData) ? requestReasonsData : ((requestReasonsData as unknown as { data: DropdownOption[] })?.data || []);
        const loadedProducts: Product[] = Array.isArray(productsData) ? productsData as Product[] : ((productsData as { data: Product[] })?.data || []);
        const companies = Array.isArray(companiesData) ? companiesData : ((companiesData as unknown as { data: DropdownOption[] })?.data || []);

        setGovernorates(governorates);
        setCallCategories(callCategories);
        setTicketCategories(ticketCategories);
        setRequestReasons(requestReasons);
        setProducts(loadedProducts);
        setCompanies(companies);
      } catch (error) {
        console.error('Error loading dropdown data:', error);
      }
    };

    loadData();
  }, []);

  // Update cities when governorate changes
  useEffect(() => {
    if (formData.governorateId) {
      const selectedGovernorate = governorates.find(g => g.id.toString() === formData.governorateId);
      const citiesData = selectedGovernorate?.cities || [];
      setCities(citiesData);
      setFormData(prev => ({ ...prev, cityId: '' }));
    } else {
      setCities([]);
    }
  }, [formData.governorateId, governorates]);

  const handleInputChange = (field: keyof FormData) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const value = e.target.value;
    setFormData(prev => ({ ...prev, [field]: value }));
    setHasChanges(true);
    setErrors(prev => ({ ...prev, [field]: '' })); // Clear error on input change
  };

  const handleRadioChange = (field: keyof FormData, value: string) => {
    // Only log if the value is actually changing to reduce noise
    // Commented out for better performance
    // if (formData[field] !== value) {
    //   console.log('🔘 Radio button clicked:', { field, value, tabId });
    // }
    setFormData(prev => ({ ...prev, [field]: value }));
    setHasChanges(true);
    setErrors(prev => ({ ...prev, [field]: '' })); // Clear error on radio change
  };

  // Validation function
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    if (!formData.name.trim()) newErrors.name = 'الاسم مطلوب';
    if (!formData.phone.trim()) newErrors.phone = 'رقم الهاتف مطلوب';
    else if (!/^\+?\d{7,15}$/.test(formData.phone.trim())) newErrors.phone = 'رقم الهاتف غير صحيح';
    if (!formData.governorateId) newErrors.governorateId = 'المحافظة مطلوبة';
    if (!formData.cityId) newErrors.cityId = 'المدينة مطلوبة';
    if (formData.requestType === 'maintenance') {
      if (!formData.brandId) newErrors.brandId = 'العلامة التجارية مطلوبة';
      if (!formData.productId) newErrors.productId = 'اسم المنتج مطلوب';
      if (!formData.requestReasonId) newErrors.requestReasonId = 'سبب الطلب مطلوب';
    }
    // Validate callDuration if present
    if (formData.callDurationMinutes || formData.callDurationSeconds) {
      const mm = Number(formData.callDurationMinutes);
      const ss = Number(formData.callDurationSeconds);
      if (
        (formData.callDurationMinutes && (isNaN(mm) || mm < 0)) ||
        (formData.callDurationSeconds && (isNaN(ss) || ss < 0 || ss > 59))
      ) {
        newErrors.callDuration = 'الرجاء إدخال دقائق صحيحة (>=0) وثواني بين 0 و 59';
      }
    }
    // Validate callReasonId for both maintenance and call
    if (!formData.callReasonId || !callCategories.some(c => c.id.toString() === formData.callReasonId)) {
      newErrors.callReasonId = 'يرجى اختيار فئة المكالمة من القائمة';
    }
    // Validate call description is required
    if (!formData.callResult.trim()) {
      newErrors.callResult = 'وصف المكالمة مطلوب';
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async () => {
    console.log('📝 SUBMIT STARTED');
    console.log('📝 Current form data:', formData);
    console.log('📝 Call type at submit:', formData.callType);
    console.log('📝 Request type at submit:', formData.requestType);
    
    if (!hasChanges) return;
    if (!validateForm()) return;

    setIsSubmitting(true);

    try {
      const companyId = getCurrentUserCompanyId();
      const userId = getCurrentUserId();
      
      if (companyId === null || userId === null) {
        setToast('خطأ في المصادقة. يرجى تسجيل الدخول مرة أخرى.');
        return;
      }
      
      const customerData = {
        companyId,
        name: formData.name,
        address: formData.address,
        notes: formData.notes,
        governorateId: formData.governorateId ? parseInt(formData.governorateId) : null,
        cityId: formData.cityId ? parseInt(formData.cityId) : null,
        phones: formData.phone ? [{
          phone: formData.phone,
          phoneType: "mobile"
        }] : [],
        createdBy: userId
      };

      let result;

      // Format call duration as mm:ss string with leading zeros
      let callDurationString = '';
      if (formData.callDurationMinutes || formData.callDurationSeconds) {
        const mm = String(formData.callDurationMinutes || '0').padStart(2, '0');
        const ss = String(formData.callDurationSeconds || '0').padStart(2, '0');
        callDurationString = `${mm}:${ss}`;
      } else {
        callDurationString = '00:00';
      }

      console.log('📝 Request type check:', formData.requestType);
      
      if (formData.requestType === 'call') {
        console.log('📝 Creating customer with CALL');
        console.log('📝 Call type being sent:', formData.callType);
        
        // Create customer with call
        const callData = {
          ...customerData,
          call: {
            callType: formData.callType,
            categoryId: parseInt(formData.callReasonId),
            description: formData.callResult, // Now 'وصف المكالمة'
            callNotes: formData.callNotes, // New field
            callDuration: callDurationString
          }
        };
        
        console.log('📝 Call data being sent to API:', callData);
        result = await createCustomerWithCall(callData);
        console.log('📝 API response:', result);
      } else {
        console.log('📝 Creating customer with TICKET (maintenance)');
        console.log('📝 Call type for ticket:', formData.callType);
        // Create customer with ticket (maintenance)
        const ticketData = {
          ...customerData,
          ticket: {
            ticketCatId: ticketCategories[0]?.id || 1, // Default to first ticket category
            description: "Maintenance request",
            status: "open",
            priority: "medium",
            ticketItems: [{
              productId: parseInt(formData.productId),
              productSize: `${formData.length || ''} × ${formData.width || ''} × ${formData.height || ''}`.replace(/^ × | × $|^ × × $/g, '').trim(),
              quantity: parseInt(formData.quantity) || 1,
              purchaseDate: formData.purchaseDate ? formData.purchaseDate : null,
              purchaseLocation: formData.purchasePlace,
              requestReasonId: parseInt(formData.requestReasonId),
              requestReasonDetail: formData.requestReasonDetail
            }],
            ticketCall: {
              callType: formData.callType || 'incoming',
              callCatId: formData.callReasonId ? parseInt(formData.callReasonId) : 1,
              description: formData.callResult || 'Initial ticket call', // Now 'وصف المكالمة'
              callNotes: formData.callNotes || '', // New field
              callDuration: callDurationString,
              createdBy: userId
            }
          }
        };
        
        console.log('📝 Ticket data being sent to API:', ticketData);
        result = await createCustomerWithTicket(ticketData);
        console.log('📝 API response:', result);
      }

      if (onSubmit) {
        // Always use the correct customer ID, regardless of backend response shape
        const customerId = result?.data?.customerId || result?.data?.id;
        onSubmit(customerId, formData.name);
      }

      // Don't reset form here - let the parent component handle clearing the form data
      // The parent will clear the form data after successful submission
      setToast('تم حفظ البيانات بنجاح');
      // Redirect to customer data page
      const customerId = result?.data?.id;
      if (customerId) {
        // router.push(`/customer/${customerId}`); // Removed as per edit hint
      }
    } catch (error) {
      console.error('Error creating record:', error);
      setToast('فشل في حفظ البيانات. يرجى المحاولة مرة أخرى.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const toggleForms = (type: 'maintenance' | 'call') => {
    setFormData(prev => ({ ...prev, requestType: type }));
    setHasChanges(true);
    setErrors(prev => ({ ...prev, productId: '', brandId: '', quantity: '', length: '', width: '', height: '', purchaseDate: '', purchasePlace: '', requestReasonId: '', requestReasonDetail: '', callReasonId: '', callResult: '', callNotes: '', callDurationMinutes: '', callDurationSeconds: '' })); // Clear maintenance fields on toggle
  };

  // UI/UX: Increased spacing and input sizes
  const fieldStyle = {
    marginBottom: '24px',
  };
  const inputStyle = {
    width: '100%',
    padding: '16px 12px',
    fontSize: '18px',
    height: '48px',
    border: '1px solid #e0e0e0',
    background: '#f7f7f7',
    borderRadius: '6px',
  };
  const selectStyle: StylesConfig = {
    control: (base: CSSObjectWithLabel) => ({
      ...base,
      minHeight: '48px',
      fontSize: '18px',
      borderRadius: '6px',
      marginBottom: '0',
    }),
    menu: (base: CSSObjectWithLabel) => ({ ...base, zIndex: 9999 }),
  };

  return (
    <div style={{
      fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif",
      backgroundColor: '#f5f5f5',
      direction: 'rtl',
      textAlign: 'right',
      padding: '20px',
      minHeight: '100vh'
    }}>
      {toast && <Toast message={toast} onClose={() => setToast(null)} />}
      <div style={{ maxWidth: '1200px', margin: '0 auto' }}>


        {/* Header and Main Row */}
        <div style={{
          display: 'flex',
          flexDirection: 'row-reverse',
          alignItems: 'flex-start',
          gap: '24px',
          marginBottom: '30px'
        }}>


          {/* Save Button */}
          <button
            onClick={handleSubmit}
            disabled={!hasChanges || isSubmitting}
            style={{
              backgroundColor: hasChanges ? 'rgb(0, 123, 255)' : '#ccc',
              color: 'white',
              border: 'none',
              padding: '12px 24px',
              borderRadius: '6px',
              fontSize: '16px',
              cursor: hasChanges ? 'pointer' : 'not-allowed',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              minWidth: '140px',
              height: '56px',
              marginTop: '0'
            }}
          >
            <span>💾</span>
            {isSubmitting ? 'جاري الحفظ...' : 'حفظ التحميل'}
          </button>


          {/* Order Details Section */}
          <div style={{
            background: 'white',
            borderRadius: '4px',
            padding: '18px',
            border: '1px solid #ddd',
            flex: formData.requestType === 'maintenance' ? '0 0 40%' : '0 0 50%'
          }}>
            <div style={{
              backgroundColor: '#e8f5e8',
              margin: '-18px -18px 18px -18px',
              padding: '10px 18px',
              borderRadius: '4px 4px 0 0',
              fontWeight: 'bold',
              color: '#2d5a2d',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}>
              تفاصيل الطلب
              <span style={{ marginLeft: 'auto' }}>⚙️</span>
            </div>

            <div style={{ marginBottom: '8px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '500',
                color: '#333'
              }}>
                نوع الطلب:
              </label>
              <div style={{
                display: 'flex',
                gap: '0',
                marginTop: '6px',
                borderRadius: '8px',
                overflow: 'hidden',
                border: '1px solid #b0b0b0',
                background: 'none',
                width: 'fit-content'
              }}>
                <div
                  onClick={() => toggleForms('maintenance')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    padding: '6px 22px',
                    border: 'none',
                    background: formData.requestType === 'maintenance' ? '#666' : '#f5f5f5',
                    fontSize: '15px',
                    cursor: 'pointer',
                    color: formData.requestType === 'maintenance' ? '#fff' : '#222',
                    fontWeight: formData.requestType === 'maintenance' ? '600' : '500',
                    borderRadius: '8px 0 0 8px',
                    transition: 'background 0.15s, color 0.15s'
                  }}
                >
                  صيانة
                </div>
                <div
                  onClick={() => toggleForms('call')}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    padding: '6px 22px',
                    border: 'none',
                    background: formData.requestType === 'call' ? '#666' : '#f5f5f5',
                    fontSize: '15px',
                    cursor: 'pointer',
                    color: formData.requestType === 'call' ? '#fff' : '#222',
                    fontWeight: formData.requestType === 'call' ? '600' : '500',
                    borderRadius: '0 8px 8px 0',
                    transition: 'background 0.15s, color 0.15s'
                  }}
                >
                  مكالمة
                </div>
              </div>
            </div>

            {/* Maintenance Form */}
            {formData.requestType === 'maintenance' && (
              <div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div style={fieldStyle}>
                    <Select
                      options={products
                        .filter(p => !formData.brandId || p.company_id?.toString() === formData.brandId)
                        .map(p => ({ value: p.id, label: p.product_name }))}
                      value={(() => {
                        const selected = products.find(p => p.id.toString() === formData.productId);
                        return selected ? { value: selected.id, label: selected.product_name } : null;
                      })()}
                      onChange={option => setFormData(prev => ({ ...prev, productId: (option as { value: string } | null)?.value?.toString() || '' }))}
                      placeholder="اسم المنتج"
                      styles={{
                        ...selectStyle,
                        menuPortal: (base: CSSObjectWithLabel) => ({ ...base, zIndex: 9999 })
                      }}
                      isSearchable
                      isDisabled={!formData.brandId}
                      menuPortalTarget={typeof window !== 'undefined' ? document.body : null}
                      menuPosition="fixed"
                    />
                    {errors.productId && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.productId}</div>}
                  </div>
                  <div style={fieldStyle}>
                    <Select
                      options={companies.map(toSelectOption)}
                      value={(() => {
                        const selected = companies.find(b => b.id.toString() === formData.brandId);
                        return selected ? { value: selected.id, label: selected.name } : null;
                      })()}
                      onChange={option => {
                        setFormData(prev => ({ ...prev, brandId: (option as { value: string } | null)?.value?.toString() || '', productId: '' }));
                        setHasChanges(true);
                        setErrors(prev => ({ ...prev, productId: '' })); // Clear product error
                      }}
                      placeholder="العلامة التجارية"
                      styles={{
                        ...selectStyle,
                        menuPortal: (base: CSSObjectWithLabel) => ({ ...base, zIndex: 9999 })
                      }}
                      isSearchable
                      menuPortalTarget={typeof window !== 'undefined' ? document.body : null}
                      menuPosition="fixed"
                    />
                    {errors.brandId && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.brandId}</div>}
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div style={{ position: 'relative', marginBottom: '10px' }}>
                    <input
                      type="number"
                      value={formData.quantity}
                      onChange={handleInputChange('quantity')}
                      placeholder=" "
                      style={inputStyle}
                    />
                    <label style={{
                      position: 'absolute',
                      right: formData.quantity ? '8px' : '12px',
                      top: formData.quantity ? '-12px' : '50%',
                      transform: formData.quantity ? 'none' : 'translateY(-50%)',
                      color: formData.quantity ? '#007bff' : '#6c757d',
                      fontSize: formData.quantity ? '12px' : '14px',
                      background: formData.quantity ? '#fff' : 'transparent',
                      padding: formData.quantity ? '0 6px' : '0 4px',
                      zIndex: 2,
                      transition: '0.15s all',
                      pointerEvents: 'none'
                    }}>
                      كمية
                    </label>
                    {errors.quantity && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.quantity}</div>}
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
                    <div style={{ position: 'relative', marginBottom: '10px' }}>
                      <input
                        type="text"
                        value={formData.length}
                        onChange={handleInputChange('length')}
                        placeholder=" "
                        style={inputStyle}
                      />
                      <label style={{
                        position: 'absolute',
                        right: formData.length ? '8px' : '12px',
                        top: formData.length ? '-12px' : '50%',
                        transform: formData.length ? 'none' : 'translateY(-50%)',
                        color: formData.length ? '#007bff' : '#6c757d',
                        fontSize: formData.length ? '12px' : '14px',
                        background: formData.length ? '#fff' : 'transparent',
                        padding: formData.length ? '0 6px' : '0 4px',
                        zIndex: 2,
                        transition: '0.15s all',
                        pointerEvents: 'none'
                      }}>
                        طول
                      </label>
                      {errors.length && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.length}</div>}
                    </div>
                    <div style={{ position: 'relative', marginBottom: '10px' }}>
                      <input
                        type="text"
                        value={formData.width}
                        onChange={handleInputChange('width')}
                        placeholder=" "
                        style={inputStyle}
                      />
                      <label style={{
                        position: 'absolute',
                        right: formData.width ? '8px' : '12px',
                        top: formData.width ? '-12px' : '50%',
                        transform: formData.width ? 'none' : 'translateY(-50%)',
                        color: formData.width ? '#007bff' : '#6c757d',
                        fontSize: formData.width ? '12px' : '14px',
                        background: formData.width ? '#fff' : 'transparent',
                        padding: formData.width ? '0 6px' : '0 4px',
                        zIndex: 2,
                        transition: '0.15s all',
                        pointerEvents: 'none'
                      }}>
                        عرض
                      </label>
                      {errors.width && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.width}</div>}
                    </div>
                    <div style={{ position: 'relative', marginBottom: '10px' }}>
                      <input
                        type="text"
                        value={formData.height}
                        onChange={handleInputChange('height')}
                        placeholder=" "
                        style={inputStyle}
                      />
                      <label style={{
                        position: 'absolute',
                        right: formData.height ? '8px' : '12px',
                        top: formData.height ? '-12px' : '50%',
                        transform: formData.height ? 'none' : 'translateY(-50%)',
                        color: formData.height ? '#007bff' : '#6c757d',
                        fontSize: formData.height ? '12px' : '14px',
                        background: formData.height ? '#fff' : 'transparent',
                        padding: formData.height ? '0 6px' : '0 4px',
                        zIndex: 2,
                        transition: '0.15s all',
                        pointerEvents: 'none'
                      }}>
                        ارتفاع
                      </label>
                      {errors.height && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.height}</div>}
                    </div>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div style={{ position: 'relative', marginBottom: '10px' }}>
                    <input
                      type="date"
                      value={formData.purchaseDate}
                      onChange={handleInputChange('purchaseDate')}
                      style={inputStyle}
                    />
                    <label style={{
                      position: 'absolute',
                      right: '8px',
                      top: '-12px',
                      color: '#007bff',
                      fontSize: '12px',
                      background: '#fff',
                      padding: '0 6px',
                      zIndex: 2
                    }}>
                      تاريخ الشراء
                    </label>
                    {errors.purchaseDate && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.purchaseDate}</div>}
                  </div>
                  <div style={{ position: 'relative', marginBottom: '10px' }}>
                    <input
                      type="text"
                      value={formData.purchasePlace}
                      onChange={handleInputChange('purchasePlace')}
                      placeholder=" "
                      style={inputStyle}
                    />
                    <label style={{
                      position: 'absolute',
                      right: formData.purchasePlace ? '8px' : '12px',
                      top: formData.purchasePlace ? '-12px' : '50%',
                      transform: formData.purchasePlace ? 'none' : 'translateY(-50%)',
                      color: formData.purchasePlace ? '#007bff' : '#6c757d',
                      fontSize: formData.purchasePlace ? '12px' : '14px',
                      background: formData.purchasePlace ? '#fff' : 'transparent',
                      padding: formData.purchasePlace ? '0 6px' : '0 4px',
                      zIndex: 2,
                      transition: '0.15s all',
                      pointerEvents: 'none'
                    }}>
                      مكان الشراء
                    </label>
                    {errors.purchasePlace && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.purchasePlace}</div>}
                  </div>
                </div>

                <div style={fieldStyle}>
                  <Select
                    options={requestReasons.map(toSelectOption)}
                    value={requestReasons.find(r => r.id.toString() === formData.requestReasonId) ? toSelectOption(requestReasons.find(r => r.id.toString() === formData.requestReasonId)!) : null}
                    onChange={option => setFormData(prev => ({ ...prev, requestReasonId: (option as { value: string } | null)?.value?.toString() || '' }))}
                    placeholder="سبب الطلب"
                    styles={{
                      ...selectStyle,
                      menuPortal: (base: CSSObjectWithLabel) => ({ ...base, zIndex: 9999 })
                    }}
                    isSearchable
                    isDisabled={requestReasons.length === 0}
                    menuPortalTarget={typeof window !== 'undefined' ? document.body : null}
                    menuPosition="fixed"
                  />
                  {errors.requestReasonId && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.requestReasonId}</div>}
                </div>

                <div style={{ position: 'relative', marginBottom: '10px' }}>
                  <textarea
                    value={formData.requestReasonDetail}
                    onChange={handleInputChange('requestReasonDetail')}
                    placeholder=" "
                    style={{
                      width: '100%',
                      padding: '12px 8px',
                      fontSize: '14px',
                      minHeight: '38px',
                      border: '1px solid #e0e0e0',
                      background: '#f7f7f7',
                      borderRadius: '4px',
                      resize: 'vertical'
                    }}
                  />
                  <label style={{
                    position: 'absolute',
                    right: formData.requestReasonDetail ? '8px' : '12px',
                    top: formData.requestReasonDetail ? '-12px' : '12px',
                    color: formData.requestReasonDetail ? '#007bff' : '#6c757d',
                    fontSize: formData.requestReasonDetail ? '12px' : '14px',
                    background: formData.requestReasonDetail ? '#fff' : 'transparent',
                    padding: formData.requestReasonDetail ? '0 6px' : '0 4px',
                    zIndex: 2,
                    transition: '0.15s all',
                    pointerEvents: 'none'
                  }}>
                    سبب الطلب بالتفصيل
                  </label>
                  {errors.requestReasonDetail && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.requestReasonDetail}</div>}
                </div>

                {/* Call fields for maintenance */}
                <div style={{ marginBottom: '8px' }}>
                  <label style={{
                    display: 'block',
                    marginBottom: '8px',
                    fontWeight: '500',
                    color: '#333'
                  }}>
                    نوع المكالمة:
                  </label>
                  <div style={{
                    display: 'flex',
                    gap: '18px',
                    alignItems: 'center',
                    marginTop: '6px'
                  }}>
                    <label style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '5px',
                      fontSize: '14px',
                      cursor: 'pointer'
                    }}>
                      <input
                        type="radio"
                        name={`callTypeMaintenance-${tabId}`}
                        value="outgoing"
                        checked={formData.callType === 'outgoing'}
                        onChange={() => handleRadioChange('callType', 'outgoing')}
                        style={{
                          accentColor: '#007bff',
                          width: '16px',
                          height: '16px'
                        }}
                      />
                      <span>صادر</span>
                    </label>
                    <label style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '5px',
                      fontSize: '14px',
                      cursor: 'pointer'
                    }}>
                      <input
                        type="radio"
                        name={`callTypeMaintenance-${tabId}`}
                        value="incoming"
                        checked={formData.callType === 'incoming'}
                        onChange={() => handleRadioChange('callType', 'incoming')}
                        style={{
                          accentColor: '#007bff',
                          width: '16px',
                          height: '16px'
                        }}
                      />
                      <span>وارد</span>
                    </label>
                  </div>
                </div>

                <div style={fieldStyle}>
                  <Select
                    options={callCategories.map(toSelectOption)}
                    value={callCategories.find(c => c.id.toString() === formData.callReasonId) ? toSelectOption(callCategories.find(c => c.id.toString() === formData.callReasonId)!) : null}
                    onChange={option => setFormData(prev => ({ ...prev, callReasonId: (option as { value: string } | null)?.value?.toString() || '' }))}
                    placeholder="فئة المكالمة"
                    styles={{
                      ...selectStyle,
                      menuPortal: (base: CSSObjectWithLabel) => ({ ...base, zIndex: 9999 })
                    }}
                    isSearchable
                    isDisabled={callCategories.length === 0}
                    menuPortalTarget={typeof window !== 'undefined' ? document.body : null}
                    menuPosition="fixed"
                    isClearable={false}
                  />
                  {errors.callReasonId && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.callReasonId}</div>}
                </div>

                <div style={{ position: 'relative', marginBottom: '10px' }}>
                  <textarea
                    value={formData.callResult}
                    onChange={handleInputChange('callResult')}
                    placeholder=" "
                    style={{
                      width: '100%',
                      padding: '12px 8px',
                      fontSize: '14px',
                      minHeight: '38px',
                      border: '1px solid #e0e0e0',
                      background: '#f7f7f7',
                      borderRadius: '4px',
                      resize: 'vertical'
                    }}
                  />
                  <label style={{
                    position: 'absolute',
                    right: formData.callResult ? '8px' : '12px',
                    top: formData.callResult ? '-12px' : '12px',
                    color: formData.callResult ? '#007bff' : '#6c757d',
                    fontSize: formData.callResult ? '12px' : '14px',
                    background: formData.callResult ? '#fff' : 'transparent',
                    padding: formData.callResult ? '0 6px' : '0 4px',
                    zIndex: 2,
                    transition: '0.15s all',
                    pointerEvents: 'none'
                  }}>
                    وصف المكالمة
                  </label>
                  {errors.callResult && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.callResult}</div>}
                </div>
                <div style={{ position: 'relative', marginBottom: '10px' }}>
                  <textarea
                    value={formData.callNotes}
                    onChange={handleInputChange('callNotes')}
                    placeholder=" "
                    style={{
                      width: '100%',
                      padding: '12px 8px',
                      fontSize: '14px',
                      minHeight: '38px',
                      border: '1px solid #e0e0e0',
                      background: '#f7f7f7',
                      borderRadius: '4px',
                      resize: 'vertical'
                    }}
                  />
                  <label style={{
                    position: 'absolute',
                    right: formData.callNotes ? '8px' : '12px',
                    top: formData.callNotes ? '-12px' : '12px',
                    color: formData.callNotes ? '#007bff' : '#6c757d',
                    fontSize: formData.callNotes ? '12px' : '14px',
                    background: formData.callNotes ? '#fff' : 'transparent',
                    padding: formData.callNotes ? '0 6px' : '0 4px',
                    zIndex: 2,
                    transition: '0.15s all',
                    pointerEvents: 'none'
                  }}>
                    ملاحظات المكالمة
                  </label>
                </div>
                <div style={{ display: 'flex', gap: '8px', marginBottom: '10px' }}>
                  <div style={{ position: 'relative', width: '50%' }}>
                    <input
                      type="number"
                      value={formData.callDurationMinutes}
                      onChange={handleInputChange('callDurationMinutes')}
                      style={inputStyle}
                      min={0}
                    />
                    <label style={{
                      position: 'absolute',
                      right: formData.callDurationMinutes ? '8px' : '12px',
                      top: formData.callDurationMinutes ? '-12px' : '50%',
                      transform: formData.callDurationMinutes ? 'none' : 'translateY(-50%)',
                      color: formData.callDurationMinutes ? '#007bff' : '#6c757d',
                      fontSize: formData.callDurationMinutes ? '12px' : '14px',
                      background: formData.callDurationMinutes ? '#fff' : 'transparent',
                      padding: formData.callDurationMinutes ? '0 6px' : '0 4px',
                      zIndex: 2,
                      transition: '0.15s all',
                      pointerEvents: 'none'
                    }}>
                      دقائق
                    </label>
                  </div>
                  <div style={{ position: 'relative', width: '50%' }}>
                    <input
                      type="number"
                      value={formData.callDurationSeconds}
                      onChange={handleInputChange('callDurationSeconds')}
                      style={inputStyle}
                      min={0}
                      max={59}
                    />
                    <label style={{
                      position: 'absolute',
                      right: formData.callDurationSeconds ? '8px' : '12px',
                      top: formData.callDurationSeconds ? '-12px' : '50%',
                      transform: formData.callDurationSeconds ? 'none' : 'translateY(-50%)',
                      color: formData.callDurationSeconds ? '#007bff' : '#6c757d',
                      fontSize: formData.callDurationSeconds ? '12px' : '14px',
                      background: formData.callDurationSeconds ? '#fff' : 'transparent',
                      padding: formData.callDurationSeconds ? '0 6px' : '0 4px',
                      zIndex: 2,
                      transition: '0.15s all',
                      pointerEvents: 'none'
                    }}>
                      ثواني
                    </label>
                  </div>
                </div>
                {errors.callDuration && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.callDuration}</div>}
              </div>
            )}

            {/* Call Form */}
            {formData.requestType === 'call' && (
              <div>
                <div style={{ marginBottom: '8px' }}>
                  <label style={{
                    display: 'block',
                    marginBottom: '8px',
                    fontWeight: '500',
                    color: '#333'
                  }}>
                    نوع المكالمة:
                  </label>
                  <div style={{
                    display: 'flex',
                    gap: '18px',
                    alignItems: 'center',
                    marginTop: '6px'
                  }}>
                    <label style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '5px',
                      fontSize: '14px',
                      cursor: 'pointer'
                    }}>
                      <input
                        type="radio"
                        name={`callType-${tabId}`}
                        value="outgoing"
                        checked={formData.callType === 'outgoing'}
                        onChange={() => handleRadioChange('callType', 'outgoing')}
                        style={{
                          accentColor: '#007bff',
                          width: '16px',
                          height: '16px'
                        }}
                      />
                      <span>صادر</span>
                    </label>
                    <label style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '5px',
                      fontSize: '14px',
                      cursor: 'pointer'
                    }}>
                      <input
                        type="radio"
                        name={`callType-${tabId}`}
                        value="incoming"
                        checked={formData.callType === 'incoming'}
                        onChange={() => handleRadioChange('callType', 'incoming')}
                        style={{
                          accentColor: '#007bff',
                          width: '16px',
                          height: '16px'
                        }}
                      />
                      <span>وارد</span>
                    </label>
                  </div>
                </div>

                <div style={fieldStyle}>
                  <Select
                    options={callCategories.map(toSelectOption)}
                    value={callCategories.find(c => c.id.toString() === formData.callReasonId) ? toSelectOption(callCategories.find(c => c.id.toString() === formData.callReasonId)!) : null}
                    onChange={option => setFormData(prev => ({ ...prev, callReasonId: (option as { value: string } | null)?.value?.toString() || '' }))}
                    placeholder="فئة المكالمة"
                    styles={{
                      ...selectStyle,
                      menuPortal: (base: CSSObjectWithLabel) => ({ ...base, zIndex: 9999 })
                    }}
                    isSearchable
                    isDisabled={callCategories.length === 0}
                    menuPortalTarget={typeof window !== 'undefined' ? document.body : null}
                    menuPosition="fixed"
                    isClearable={false}
                  />
                  {errors.callReasonId && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.callReasonId}</div>}
                </div>

                <div style={{ position: 'relative', marginBottom: '10px' }}>
                  <textarea
                    value={formData.callResult}
                    onChange={handleInputChange('callResult')}
                    placeholder=" "
                    style={{
                      width: '100%',
                      padding: '12px 8px',
                      fontSize: '14px',
                      minHeight: '38px',
                      border: '1px solid #e0e0e0',
                      background: '#f7f7f7',
                      borderRadius: '4px',
                      resize: 'vertical'
                    }}
                  />
                  <label style={{
                    position: 'absolute',
                    right: formData.callResult ? '8px' : '12px',
                    top: formData.callResult ? '-12px' : '12px',
                    color: formData.callResult ? '#007bff' : '#6c757d',
                    fontSize: formData.callResult ? '12px' : '14px',
                    background: formData.callResult ? '#fff' : 'transparent',
                    padding: formData.callResult ? '0 6px' : '0 4px',
                    zIndex: 2,
                    transition: '0.15s all',
                    pointerEvents: 'none'
                  }}>
                    وصف المكالمة
                  </label>
                  {errors.callResult && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.callResult}</div>}
                </div>
                <div style={{ position: 'relative', marginBottom: '10px' }}>
                  <textarea
                    value={formData.callNotes}
                    onChange={handleInputChange('callNotes')}
                    placeholder=" "
                    style={{
                      width: '100%',
                      padding: '12px 8px',
                      fontSize: '14px',
                      minHeight: '38px',
                      border: '1px solid #e0e0e0',
                      background: '#f7f7f7',
                      borderRadius: '4px',
                      resize: 'vertical'
                    }}
                  />
                  <label style={{
                    position: 'absolute',
                    right: formData.callNotes ? '8px' : '12px',
                    top: formData.callNotes ? '-12px' : '12px',
                    color: formData.callNotes ? '#007bff' : '#6c757d',
                    fontSize: formData.callNotes ? '12px' : '14px',
                    background: formData.callNotes ? '#fff' : 'transparent',
                    padding: formData.callNotes ? '0 6px' : '0 4px',
                    zIndex: 2,
                    transition: '0.15s all',
                    pointerEvents: 'none'
                  }}>
                    ملاحظات المكالمة
                  </label>
                </div>
                <div style={{ display: 'flex', gap: '8px', marginBottom: '10px' }}>
                  <div style={{ position: 'relative', width: '50%' }}>
                    <input
                      type="number"
                      value={formData.callDurationMinutes}
                      onChange={handleInputChange('callDurationMinutes')}
                      style={inputStyle}
                      min={0}
                    />
                    <label style={{
                      position: 'absolute',
                      right: formData.callDurationMinutes ? '8px' : '12px',
                      top: formData.callDurationMinutes ? '-12px' : '50%',
                      transform: formData.callDurationMinutes ? 'none' : 'translateY(-50%)',
                      color: formData.callDurationMinutes ? '#007bff' : '#6c757d',
                      fontSize: formData.callDurationMinutes ? '12px' : '14px',
                      background: formData.callDurationMinutes ? '#fff' : 'transparent',
                      padding: formData.callDurationMinutes ? '0 6px' : '0 4px',
                      zIndex: 2,
                      transition: '0.15s all',
                      pointerEvents: 'none'
                    }}>
                      دقائق
                    </label>
                  </div>
                  <div style={{ position: 'relative', width: '50%' }}>
                    <input
                      type="number"
                      value={formData.callDurationSeconds}
                      onChange={handleInputChange('callDurationSeconds')}
                      style={inputStyle}
                      min={0}
                      max={59}
                    />
                    <label style={{
                      position: 'absolute',
                      right: formData.callDurationSeconds ? '8px' : '12px',
                      top: formData.callDurationSeconds ? '-12px' : '50%',
                      transform: formData.callDurationSeconds ? 'none' : 'translateY(-50%)',
                      color: formData.callDurationSeconds ? '#007bff' : '#6c757d',
                      fontSize: formData.callDurationSeconds ? '12px' : '14px',
                      background: formData.callDurationSeconds ? '#fff' : 'transparent',
                      padding: formData.callDurationSeconds ? '0 6px' : '0 4px',
                      zIndex: 2,
                      transition: '0.15s all',
                      pointerEvents: 'none'
                    }}>
                      ثواني
                    </label>
                  </div>
                </div>
                {errors.callDuration && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.callDuration}</div>}
              </div>
            )}
          </div>



          {/* White Box (Customer Data) */}
          <div style={{
            background: 'white',
            borderRadius: '4px',
            padding: '18px',
            border: '1px solid #ddd',
            flex: 1
          }}>
            <h1 style={{
              fontSize: '24px',
              fontWeight: 'bold',
              color: '#333',
              margin: 0,
              marginBottom: '18px'
            }}>
              عميل جديد
            </h1>
            {/* The rest of the customer data form will go here, move the content from the old white box here */}
            {/* ...existing customer data fields... */}
            <div style={{
              backgroundColor: '#e3f2fd',
              margin: '-18px -18px 18px -18px',
              padding: '10px 18px',
              borderRadius: '4px 4px 0 0',
              fontWeight: 'bold',
              color: '#1565c0',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center'
            }}>
              <span>بيانات العميل</span>
              <span style={{ fontSize: '18px' }}>👤</span>
            </div>

            <div style={{ position: 'relative', marginBottom: '10px' }}>
              <input
                type="text"
                value={formData.name}
                onChange={handleInputChange('name')}
                placeholder=" "
                style={inputStyle}
              />
              {errors.name && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.name}</div>}
              <label style={{
                position: 'absolute',
                right: formData.name ? '8px' : '12px',
                top: formData.name ? '-12px' : '50%',
                transform: formData.name ? 'none' : 'translateY(-50%)',
                color: formData.name ? '#007bff' : '#6c757d',
                fontSize: formData.name ? '12px' : '14px',
                background: formData.name ? '#fff' : 'transparent',
                padding: formData.name ? '0 6px' : '0 4px',
                zIndex: 2,
                transition: '0.15s all',
                pointerEvents: 'none'
              }}>
                الاسم
              </label>
            </div>

            <div style={{ position: 'relative', marginBottom: '10px' }}>
              <input
                type="tel"
                value={formData.phone}
                onChange={handleInputChange('phone')}
                placeholder=" "
                style={inputStyle}
              />
              {errors.phone && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.phone}</div>}
              <label style={{
                position: 'absolute',
                right: formData.phone ? '8px' : '12px',
                top: formData.phone ? '-12px' : '50%',
                transform: formData.phone ? 'none' : 'translateY(-50%)',
                color: formData.phone ? '#007bff' : '#6c757d',
                fontSize: formData.phone ? '12px' : '14px',
                background: formData.phone ? '#fff' : 'transparent',
                padding: formData.phone ? '0 6px' : '0 4px',
                zIndex: 2,
                transition: '0.15s all',
                pointerEvents: 'none'
              }}>
                الهاتف
              </label>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div style={fieldStyle}>
                <Select
                  options={governorates.map(toSelectOption)}
                  value={governorates.find(g => g.id.toString() === formData.governorateId) ? toSelectOption(governorates.find(g => g.id.toString() === formData.governorateId)!) : null}
                  onChange={option => {
                    setFormData(prev => ({ ...prev, governorateId: (option as { value: string } | null)?.value?.toString() || '', cityId: '' }));
                    setHasChanges(true);
                    setErrors(prev => ({ ...prev, cityId: '' })); // Clear city error
                  }}
                  placeholder="المحافظة"
                  styles={{
                    ...selectStyle,
                    menuPortal: (base: CSSObjectWithLabel) => ({ ...base, zIndex: 9999 })
                  }}
                  isSearchable
                  menuPortalTarget={typeof window !== 'undefined' ? document.body : null}
                  menuPosition="fixed"
                />
                {errors.governorateId && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.governorateId}</div>}
              </div>
              <div style={fieldStyle}>
                <Select
                  options={cities.map(toSelectOption)}
                  value={cities.find(c => c.id.toString() === formData.cityId) ? toSelectOption(cities.find(c => c.id.toString() === formData.cityId)!) : null}
                  onChange={option => setFormData(prev => ({ ...prev, cityId: (option as { value: string } | null)?.value?.toString() || '' }))}
                  placeholder="المدينة"
                  styles={{
                    ...selectStyle,
                    menuPortal: (base: CSSObjectWithLabel) => ({ ...base, zIndex: 9999 })
                  }}
                  isSearchable
                  isDisabled={!formData.governorateId}
                  menuPortalTarget={typeof window !== 'undefined' ? document.body : null}
                  menuPosition="fixed"
                />
                {errors.cityId && <div style={{ color: '#d32f2f', fontSize: '14px', marginTop: '4px' }}>{errors.cityId}</div>}
              </div>
            </div>

            <div style={{ position: 'relative', marginBottom: '10px' }}>
              <input
                type="text"
                value={formData.address}
                onChange={handleInputChange('address')}
                placeholder=" "
                style={inputStyle}
              />
              <label style={{
                position: 'absolute',
                right: formData.address ? '8px' : '12px',
                top: formData.address ? '-12px' : '50%',
                transform: formData.address ? 'none' : 'translateY(-50%)',
                color: formData.address ? '#007bff' : '#6c757d',
                fontSize: formData.address ? '12px' : '14px',
                background: formData.address ? '#fff' : 'transparent',
                padding: formData.address ? '0 6px' : '0 4px',
                zIndex: 2,
                transition: '0.15s all',
                pointerEvents: 'none'
              }}>
                العنوان
              </label>
            </div>

            <div style={{ position: 'relative', marginBottom: '10px' }}>
              <textarea
                value={formData.notes}
                onChange={handleInputChange('notes')}
                placeholder=" "
                style={{
                  width: '100%',
                  padding: '12px 8px',
                  fontSize: '14px',
                  minHeight: '38px',
                  border: '1px solid #e0e0e0',
                  background: '#f7f7f7',
                  borderRadius: '4px',
                  resize: 'vertical'
                }}
              />
              <label style={{
                position: 'absolute',
                right: formData.notes ? '8px' : '12px',
                top: formData.notes ? '-12px' : '12px',
                color: formData.notes ? '#007bff' : '#6c757d',
                fontSize: formData.notes ? '12px' : '14px',
                background: formData.notes ? '#fff' : 'transparent',
                padding: formData.notes ? '0 6px' : '0 4px',
                zIndex: 2,
                transition: '0.15s all',
                pointerEvents: 'none'
              }}>
                ملاحظات
              </label>
            </div>
          </div>





          
        </div>
      </div>
    </div>
  );
}