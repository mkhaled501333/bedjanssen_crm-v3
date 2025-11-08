'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { Modal, Form, Input, Select, DatePicker, Button, Row, Col, Radio, ConfigProvider, notification, InputNumber } from 'antd';
import moment from 'moment';
import { getCallCategories } from '../../../api';
import { getTicketCategories, getRequestReasons, getProducts, getCompanies } from '../../../../masterdata/api';
import styles from './AddNewTicketModal.module.css';

const { Option } = Select;
const { TextArea } = Input;

interface AddNewTicketModalProps {
  onClose: () => void;
  onSave: (ticketData: Record<string, unknown>) => void;
  onFormChange: (formData: Record<string, unknown>) => void; // Form change handler
  customerName: string;
  customerId: number;
  initialFormData?: Record<string, unknown> | null;
  visible: boolean;
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

const mockTicketCategories = [
  { id: 1, name: 'استفسار عن منتج' },
  { id: 2, name: 'شكوى من منتج' },
  { id: 3, name: 'اقتراح' },
];
const mockRequestReasons = [
    { id: 1, name: 'منتج تالف' },
    { id: 2, name: 'منتج منتهي الصلاحية' },
    { id: 3, name: 'تأثير عكسي' },
];
const mockCallCategories = [
    { id: 1, name: 'استفسار' },
    { id: 2, name: 'شكوى' },
    { id: 3, name: 'متابعة' },
];


export function AddNewTicketModal({ onClose, onSave, onFormChange, customerName, initialFormData, visible }: AddNewTicketModalProps): JSX.Element {
  const [form] = Form.useForm();
  const [api, contextHolder] = notification.useNotification();
  const [callCategories, setCallCategories] = useState<MasterDataItem[]>([]);
  const [ticketCategories, setTicketCategories] = useState<MasterDataItem[]>([]);
  const [requestReasons, setRequestReasons] = useState<MasterDataItem[]>([]);
  const [products, setProducts] = useState<ProductDataItem[]>([]);
  const [companies, setCompanies] = useState<CompanyDataItem[]>([]);
  const [selectedCompany, setSelectedCompany] = useState<number | null>(null);
  
  const [loading, setLoading] = useState({
    callCategories: false,
    ticketCategories: false,
    requestReasons: false,
    products: false,
    companies: false,
  });

  useEffect(() => {
    const fetchMasterData = async () => {
      setLoading(prev => ({ ...prev, callCategories: true, ticketCategories: true, requestReasons: true, products: true, companies: true }));
      try {
        const [calls, tickets, reasons, prods, comps] = await Promise.all([
          getCallCategories(),
          getTicketCategories(),
          getRequestReasons(),
          getProducts(),
          getCompanies(),
        ]);
        setCallCategories(calls);
        setTicketCategories(tickets);
        setRequestReasons(reasons);
        setProducts(prods);
        setCompanies(comps);

      } catch (error) {
        console.error("Failed to fetch master data, using mock data.", error);
        api.warning({
          message: 'Failed to fetch master data',
          description: 'Using mock data for dropdowns. Please ensure backend endpoints are correctly configured.',
          duration: 15
        });
        setCallCategories(mockCallCategories);
        setTicketCategories(mockTicketCategories);
        setRequestReasons(mockRequestReasons);
      } finally {
        setLoading(prev => ({ ...prev, callCategories: false, ticketCategories: false, requestReasons: false, products: false, companies: false }));
      }
    };
    fetchMasterData();
  }, [api]);

  // Debounced form change handler
  const debouncedFormChange = useCallback(
    (allValues: Record<string, unknown>) => {
      const timeoutId = setTimeout(() => {
        onFormChange(allValues);
      }, 300);
      return () => clearTimeout(timeoutId);
    },
    [onFormChange]
  );

  // Restore form data when modal opens
  const prevVisibleRef = useRef<boolean>(visible);

  useEffect(() => {
    const wasVisible = prevVisibleRef.current;

    if (visible && !wasVisible) {
      if (initialFormData) {
        form.setFieldsValue(initialFormData);
        if (initialFormData.companyId) {
          setSelectedCompany(initialFormData.companyId as number);
        } else {
          setSelectedCompany(null);
        }
      } else {
        form.resetFields();
        setSelectedCompany(null);
      }
    }

    prevVisibleRef.current = visible;
  }, [visible, initialFormData, form]);

  const handleSave = () => {
    form.validateFields().then(values => {
      console.log('Form values:', values);
      const ticketData = {
        companyId: values.companyId, // Include companyId from form
        ticketCatId: values.ticketCatId,
        description: values.description || '',
        priority: values.priority,
        call: {
          callType: values.callType,
          callCatId: values.callCatId,
          description: values.callDescription || '',
          callNotes: values.callNotes || '',
          callDuration: values.callDuration || '0:0',
        },
        item: {
          productId: values.productId,
          quantity: values.quantity,
          productSize: `${values.length || ''} × ${values.width || ''} × ${values.height || ''}`.replace(/^ × | × $|^ × × $/g, '').trim(),
          purchaseDate: values.purchaseDate.format('YYYY-MM-DD'),
          purchaseLocation: values.purchaseLocation,
          requestReasonId: values.requestReasonId,
          requestReasonDetail: values.requestReasonDetail,
        }
      };
      console.log('Ticket data to save:', ticketData);
      onSave(ticketData);
      // Don't reset fields here - let the parent component handle clearing the form data
    }).catch(info => {
      console.log('Validate Failed:', info);
      api.error({
        message: 'خطأ في التحقق من البيانات',
        description: 'يرجى التحقق من جميع الحقول المطلوبة',
      });
    });
  };

  return (
    <ConfigProvider direction="rtl">
      {contextHolder}
      <Modal
        title={`إضافة تذكرة جديدة لـ ${customerName}`}
        open={visible}
        onCancel={onClose}
        destroyOnHidden={false}
        width={960}
        footer={[
          <Button key="back" onClick={onClose}>
            إلغاء
          </Button>,
          <Button key="submit" type="primary" onClick={handleSave}>
            حفظ
          </Button>,
        ]}
        styles={{
          body: { backgroundColor: '#f0f2f5', padding: '12px' },
          header: { 
            backgroundColor: '#fff', 
            borderBottom: '1px solid #e8e8e8',
            padding: '12px 20px',
            margin: 0
          },
          content: {
            padding: 0
          },
          footer: { 
            backgroundColor: '#fff', 
            borderTop: '1px solid #e8e8e8', 
            padding: '8px 20px', 
            margin: 0
          }
        }}
      >
        <Form
          form={form}
          layout="vertical"
          name="addNewTicketForm"
          className={styles.compactForm}
          key={initialFormData ? 'restored' : 'new'}
          initialValues={{
            priority: 'low',
            quantity: 1,
            purchaseDate: moment(),
            callType: 'incoming',
          }}
          onValuesChange={(changedValues, allValues) => {
            debouncedFormChange(allValues);
          }}
          onFieldsChange={() => {
            const allValues = form.getFieldsValue();
            debouncedFormChange(allValues);
          }}
        >
          <Row gutter={16}>
            {/* Right Column (as it's RTL) */}
            <Col span={12}>
              <Row gutter={12}>
                <Col span={12}>
                  <Form.Item name="priority" label={<span className={styles.formLabel}>الأولوية</span>} rules={[{ required: true }]}>
                    <Select size="small" placeholder="اختر الأولوية">
                      <Option value="low">منخفضة</Option>
                      <Option value="medium">متوسطة</Option>
                      <Option value="high">عالية</Option>
                    </Select>
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item name="ticketCatId" label={<span className={styles.formLabel}>فئة التذكرة</span>} rules={[{ required: true }]}>
                    <Select
                      size="small"
                      showSearch
                      placeholder="اختر فئة"
                      loading={loading.ticketCategories}
                      filterOption={(input, option) =>
                        (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                      }
                      options={ticketCategories.map(cat => ({ value: cat.id, label: cat.name }))}
                    />
                  </Form.Item>
                </Col>
              </Row>

              <Form.Item name="description" label={<span className={styles.formLabel}>وصف التذكرة</span>}>
                <TextArea size="small" rows={2} placeholder="أدخل وصفًا تفصيليًا للتذكرة" />
              </Form.Item>

              <Row gutter={12}>
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

              <Row gutter={12}>
                <Col span={8}>
                  <Form.Item name="length" label={<span className={styles.formLabel}>طول</span>}>
                    <Input size="small" placeholder="مثال: 200" />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item name="width" label={<span className={styles.formLabel}>عرض</span>}>
                    <Input size="small" placeholder="مثال: 150" />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item name="height" label={<span className={styles.formLabel}>ارتفاع</span>}>
                    <Input size="small" placeholder="مثال: 100" />
                  </Form.Item>
                </Col>
              </Row>

              <Row gutter={12}>
                <Col span={12}>
                  <Form.Item 
                    name="quantity" 
                    label={<span className={styles.formLabel}>الكمية</span>}
                    rules={[
                      { required: true, message: 'الكمية مطلوبة' },
                      { 
                        type: 'number', 
                        message: 'يجب أن تكون الكمية رقم'
                      }
                    ]}
                  >
                    <InputNumber size="small" min={1} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
              </Row>
              
              <Row gutter={12}>
                <Col span={12}>
                  <Form.Item 
                    name="purchaseDate" 
                    label={<span className={styles.formLabel}>تاريخ الشراء</span>}
                    rules={[{ required: true, message: 'تاريخ الشراء مطلوب' }]}
                  >
                    <DatePicker style={{ width: '100%' }} size="small" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                    <Form.Item 
                      name="purchaseLocation" 
                      label={<span className={styles.formLabel}>مكان الشراء</span>}
                      rules={[{ required: true, message: 'مكان الشراء مطلوب' }]}
                    >
                        <Input size="small" placeholder="أدخل مكان الشراء" />
                    </Form.Item>
                </Col>
              </Row>

              <Form.Item name="requestReasonId" label={<span className={styles.formLabel}>سبب الطلب</span>} rules={[{ required: true }]}>
                <Select
                  size="small"
                  showSearch
                  placeholder="اختر سبب الطلب"
                  loading={loading.requestReasons}
                  filterOption={(input, option) =>
                    (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                  }
                  options={requestReasons.map(reason => ({ value: reason.id, label: reason.name }))}
                />
              </Form.Item>

              <Form.Item name="requestReasonDetail" label={<span className={styles.formLabel}>تفاصيل سبب الطلب</span>} rules={[{ required: true, message: 'يرجى إدخال تفاصيل سبب الطلب' }]}>
                <TextArea size="small" rows={2} placeholder="أدخل تفاصيل إضافية" />
              </Form.Item>
            </Col>

            {/* Left Column (as it's RTL) */}
            <Col span={12}>
              <Form.Item label={<span className={styles.formLabel}>نوع المكالمة</span>} name="callType" rules={[{ required: true }]}>
                <Radio.Group optionType="button" buttonStyle="solid" size="small">
                  <Radio.Button value="incoming">وارد</Radio.Button>
                  <Radio.Button value="outgoing">صادر</Radio.Button>
                </Radio.Group>
              </Form.Item>

              <Form.Item name="callCatId" label={<span className={styles.formLabel}>فئة المكالمة</span>} rules={[{ required: true }]}>
                <Select
                  size="small"
                  showSearch
                  placeholder="اختر فئة المكالمة"
                  loading={loading.callCategories}
                  filterOption={(input, option) =>
                    (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                  }
                  options={callCategories.map(cat => ({ value: cat.id, label: cat.name }))}
                />
              </Form.Item>

              <Form.Item name="callDescription" label={<span className={styles.formLabel}>وصف المكالمة</span>}>
                <TextArea size="small" rows={3} placeholder="أدخل وصفًا تفصيليًا للمكالمة" />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>
    </ConfigProvider>
  );
}