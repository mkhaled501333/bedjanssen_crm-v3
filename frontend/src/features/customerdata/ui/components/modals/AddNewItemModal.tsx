'use client';

import { useState, useEffect } from 'react';
import { Modal, Form, Input, Select, DatePicker, Button, Row, Col, InputNumber, ConfigProvider, notification } from 'antd';
import moment from 'moment';
import { getRequestReasons, getProducts, getCompanies } from '../../../../masterdata/api';
import styles from './AddNewItemModal.module.css';
import { getCurrentUserId } from '../../../../../shared/utils/auth';

const { TextArea } = Input;

interface AddNewItemModalProps {
  onClose: () => void;
  onSave: (itemData: Record<string, unknown>) => void;
  ticketId: number;
  editMode?: boolean;
  initialValues?: {
    id?: number;
    companyId?: number;
    productId?: number;
    quantity?: number;
    product_size?: string;
    purchase_date?: string;
    purchase_location?: string;
    request_reason_id?: number;
    request_reason_detail?: string;
  };
}

interface MasterDataItem {
  id: number;
  name: string;
}

interface ProductDataItem {
  id: number;
  product_name: string;
  company_id?: number;
}

interface CompanyDataItem {
    id: number;
    name: string;
}

export function AddNewItemModal({ onClose, onSave, ticketId, editMode = false, initialValues }: AddNewItemModalProps) {
  const [form] = Form.useForm();
  const [api, contextHolder] = notification.useNotification();
  const [requestReasons, setRequestReasons] = useState<MasterDataItem[]>([]);
  const [products, setProducts] = useState<ProductDataItem[]>([]);
  const [companies, setCompanies] = useState<CompanyDataItem[]>([]);
  const [selectedCompany, setSelectedCompany] = useState<number | null>(null);
  
  const [loading, setLoading] = useState({
    requestReasons: false,
    products: false,
    companies: false,
  });

  useEffect(() => {
    const fetchMasterData = async () => {
      setLoading(prev => ({ ...prev, requestReasons: true, products: true, companies: true }));
      try {
        const [reasons, prods, comps] = await Promise.all([
          getRequestReasons(),
          getProducts(),
          getCompanies(),
        ]);
        setRequestReasons(reasons);
        setProducts(prods);
        setCompanies(comps);

      } catch (error) {
        console.error("Failed to fetch master data", error);
        api.warning({
          message: 'Failed to fetch master data',
          description: 'Could not load data for dropdowns. Please ensure backend endpoints are correctly configured.',
          duration: 15
        });
      } finally {
        setLoading(prev => ({ ...prev, requestReasons: false, products: false, companies: false }));
      }
    };
    fetchMasterData();
  }, [api]);

  // Set initial values when in edit mode
  useEffect(() => {
    if (editMode && initialValues) {
      if (initialValues.companyId) {
        setSelectedCompany(initialValues.companyId);
      }
      
      const formValues = {
        companyId: initialValues.companyId,
        productId: initialValues.productId,
        quantity: initialValues.quantity || 1,
        productSize: initialValues.product_size || '',
        purchaseDate: initialValues.purchase_date ? moment(initialValues.purchase_date) : null,
        purchaseLocation: initialValues.purchase_location || '',
        requestReasonId: initialValues.request_reason_id,
        requestReasonDetail: initialValues.request_reason_detail || '',
      };
      
      form.setFieldsValue(formValues);
    }
  }, [editMode, initialValues, form]);

  const handleSave = () => {
    form.validateFields().then(values => {
      const userId = getCurrentUserId();
      
      if (!userId) {
        api.error({
          message: 'خطأ في المصادقة',
          description: 'يرجى تسجيل الدخول مرة أخرى.',
        });
        return;
      }
      
      let itemData: Record<string, unknown>;
      
      if (editMode && initialValues) {
        // In edit mode, only send changed fields
        itemData = {};
        
        // Check if companyId has changed
        if (values.companyId !== initialValues.companyId) {
          itemData.companyId = values.companyId;
        }
        if (values.productId !== initialValues.productId) {
          itemData.productId = values.productId;
        }
        if (values.quantity !== initialValues.quantity) {
          itemData.quantity = values.quantity;
        }
        if (values.productSize !== initialValues.product_size) {
          itemData.product_size = values.productSize;
        }
        
        // Handle purchase date comparison more carefully
         if (values.purchaseDate) {
           const formattedDate = values.purchaseDate.format('YYYY-MM-DD');
           // Ensure we're comparing the same format - normalize initial date
           const normalizedInitialDate = initialValues.purchase_date ? 
             moment(initialValues.purchase_date).format('YYYY-MM-DD') : null;
           
           if (formattedDate !== normalizedInitialDate) {
             itemData.purchase_date = formattedDate;
           }
         } else if (initialValues.purchase_date) {
           // If form date is null but initial had a date, this is a change
           itemData.purchase_date = null;
         }
        
        if (values.purchaseLocation !== initialValues.purchase_location) {
          itemData.purchase_location = values.purchaseLocation;
        }
        if (values.requestReasonId !== initialValues.request_reason_id) {
          itemData.request_reason_id = values.requestReasonId;
        }
        if (values.requestReasonDetail !== initialValues.request_reason_detail) {
          itemData.request_reason_detail = values.requestReasonDetail;
        }
        
        // Always include the ID for edit operations
        if (initialValues.id) {
          itemData.id = initialValues.id;
        }
        
        // If no fields changed, show a message
        if (Object.keys(itemData).length === 0 || (Object.keys(itemData).length === 1 && itemData.id)) {
          api.info({
            message: 'لا توجد تغييرات',
            description: 'لم يتم تغيير أي من البيانات.',
          });
          return;
        }
      } else {
        // In create mode, send all fields
        itemData = {
          companyId: values.companyId,
          productId: values.productId,
          quantity: values.quantity,
          product_size: values.productSize,
          purchase_date: values.purchaseDate.format('YYYY-MM-DD'),
          purchase_location: values.purchaseLocation,
          request_reason_id: values.requestReasonId,
          request_reason_detail: values.requestReasonDetail,
          createdBy: userId,
        };
      }
      
      onSave(itemData);
      form.resetFields();
    }).catch(info => {
      console.log('Validate Failed:', info);
    });
  };

  return (
    <ConfigProvider direction="rtl">
      {contextHolder}
      <Modal
        title={editMode ? `تعديل المنتج للتذكرة رقم ${ticketId}` : `إضافة منتج جديد للتذكرة رقم ${ticketId}`}
        open={true}
        onCancel={onClose}
        width={800}
        footer={[
          <Button key="back" onClick={onClose}>
            إلغاء
          </Button>,
          <Button key="submit" type="primary" onClick={handleSave}>
            حفظ
          </Button>,
        ]}
        styles={{
          body: { backgroundColor: '#f0f2f5', padding: '16px' },
          header: { 
            backgroundColor: '#fff', 
            borderBottom: '1px solid #e8e8e8',
            padding: '16px 24px',
            margin: 0
          },
          content: {
            padding: 0
          },
          footer: { 
            backgroundColor: '#fff', 
            borderTop: '1px solid #e8e8e8', 
            padding: '12px 24px', 
            margin: 0
          }
        }}
      >
        <Form
          form={form}
          layout="vertical"
          name="addNewItemForm"
          className={styles.compactForm}
          initialValues={editMode ? {} : {
            quantity: 1,
            purchaseDate: moment(),
          }}
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="companyId" label={<span className={styles.formLabel}>الشركة المصنعة</span>} rules={[{ required: true }]}>
                <Select
                  size="small"
                  showSearch
                  placeholder="اختر الشركة"
                  loading={loading.companies}
                  onChange={(value) => {
                    setSelectedCompany(value);
                    form.setFieldsValue({ productId: null }); // Reset product when company changes
                  }}
                  options={companies.map(c => ({ value: c.id, label: c.name }))}
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="productId" label={<span className={styles.formLabel}>اسم المنتج</span>} rules={[{ required: true }]}>
                <Select
                  size="small"
                  showSearch
                  placeholder="اختر المنتج"
                  loading={loading.products}
                  disabled={!selectedCompany}
                  filterOption={(input, option) =>
                    (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                  }
                  options={products
                    .filter(p => p.company_id === selectedCompany)
                    .map(p => ({ value: p.id, label: p.product_name }))
                  }
                />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={8}>
                <Form.Item name="quantity" label={<span className={styles.formLabel}>الكمية</span>} rules={[{ required: true }]}>
                    <InputNumber size="small" min={1} style={{ width: '100%' }} />
                </Form.Item>
            </Col>
            <Col span={8}>
                <Form.Item name="productSize" label={<span className={styles.formLabel}>حجم المنتج</span>}>
                    <Input size="small" placeholder="مثال: كبير، 500 مل" />
                </Form.Item>
            </Col>
             <Col span={8}>
                <Form.Item name="purchaseDate" label={<span className={styles.formLabel}>تاريخ الشراء</span>} rules={[{ required: true }]}>
                    <DatePicker size="small" style={{ width: '100%' }} format="YYYY-MM-DD" />
                </Form.Item>
            </Col>
          </Row>

           <Form.Item name="purchaseLocation" label={<span className={styles.formLabel}>مكان الشراء</span>}>
              <Input size="small" placeholder="مثال: كارفور، صيدلية العزبي" />
            </Form.Item>

          <Form.Item name="requestReasonId" label={<span className={styles.formLabel}>سبب الطلب</span>} rules={[{ required: true }]}>
            <Select
              size="small"
              showSearch
              placeholder="اختر سبب الطلب"
              loading={loading.requestReasons}
              filterOption={(input, option) =>
                (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
              }
              options={requestReasons.map(r => ({ value: r.id, label: r.name }))}
            />
          </Form.Item>

          <Form.Item name="requestReasonDetail" label={<span className={styles.formLabel}>تفاصيل سبب الطلب</span>}>
            <TextArea size="small" rows={3} placeholder="أدخل تفاصيل إضافية" />
          </Form.Item>

        </Form>
      </Modal>
    </ConfigProvider>
  );
}