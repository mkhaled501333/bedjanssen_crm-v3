'use client';

import { useState, useEffect } from 'react';
import { Modal, Form, Input, Button, notification } from 'antd';
import { TicketCategory } from '../../types';
import { addTicketCategory, updateTicketCategory } from '../../api';

interface AddEditTicketCategoryModalProps {
  visible: boolean;
  onClose: () => void;
  onSuccess: () => void;
  category?: TicketCategory;
}

export function AddEditTicketCategoryModal({ visible, onClose, onSuccess, category }: AddEditTicketCategoryModalProps) {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [api, contextHolder] = notification.useNotification();

  const isEditMode = !!category;

  useEffect(() => {
    if (category) {
      form.setFieldsValue({ name: category.name });
    } else {
      form.resetFields();
    }
  }, [category, form]);

  const handleFinish = async (values: { name: string }) => {
    setLoading(true);
    try {
      if (isEditMode && category) {
        await updateTicketCategory(category.id, values.name);
        api.success({
          message: 'Category Updated',
          description: `Category "${values.name}" has been updated successfully.`,
        });
      } else {
        await addTicketCategory(values.name);
        api.success({
          message: 'Category Added',
          description: `Category "${values.name}" has been added successfully.`,
        });
      }
      onSuccess();
      onClose();
    } catch (error) {
      console.error('Failed to save ticket category', error);
      api.error({
        message: `Failed to ${isEditMode ? 'update' : 'add'} category`,
        description: (error as Error).message || 'An unknown error occurred.',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      {contextHolder}
      <Modal
        title={isEditMode ? 'Edit Ticket Category' : 'Add Ticket Category'}
        open={visible}
        onCancel={onClose}
        footer={[
          <Button key="back" onClick={onClose}>
            Cancel
          </Button>,
          <Button key="submit" type="primary" loading={loading} onClick={() => form.submit()}>
            {isEditMode ? 'Update' : 'Add'}
          </Button>,
        ]}
      >
        <Form form={form} layout="vertical" onFinish={handleFinish}>
          <Form.Item
            name="name"
            label="Category Name"
            rules={[{ required: true, message: 'Please enter the category name' }]}
          >
            <Input />
          </Form.Item>
        </Form>
      </Modal>
    </>
  );
} 