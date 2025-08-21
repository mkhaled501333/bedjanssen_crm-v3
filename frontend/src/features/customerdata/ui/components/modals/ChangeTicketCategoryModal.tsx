
'use client';

import { useState, useEffect } from 'react';
import { Modal, Select, Button, notification } from 'antd';
import { getTicketCategories } from '../../../../masterdata/api';
import { TicketCategory } from '../../../../masterdata/types';

interface ChangeTicketCategoryModalProps {
  visible: boolean;
  onClose: () => void;
  onSave: (newCategoryId: number) => Promise<void>;
  currentCategoryId?: number;
  ticketId?: number;
}

export function ChangeTicketCategoryModal({
  visible,
  onClose,
  onSave,
  currentCategoryId,
  ticketId,
}: ChangeTicketCategoryModalProps) {
  const [loading, setLoading] = useState(false);
  const [categories, setCategories] = useState<TicketCategory[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<number | undefined>(currentCategoryId);
  const [api, contextHolder] = notification.useNotification();

  useEffect(() => {
    if (visible) {
      setLoading(true);
      getTicketCategories()
        .then(setCategories)
        .catch(err => {
          api.error({
            message: 'Failed to load categories',
            description: err.message,
          });
        })
        .finally(() => setLoading(false));
    }
  }, [visible, api]);

  useEffect(() => {
    setSelectedCategory(currentCategoryId);
  }, [currentCategoryId]);

  const handleSave = async () => {
    if (!selectedCategory) {
      api.warning({
        message: 'No category selected',
        description: 'Please select a new category before saving.',
      });
      return;
    }

    if (selectedCategory === currentCategoryId) {
      onClose();
      return;
    }

    setLoading(true);
    try {
      await onSave(selectedCategory);
      api.success({
        message: 'Category Updated',
        description: 'The ticket category has been updated successfully.',
      });
      onClose();
    } catch (error) {
      console.error('Failed to save ticket category', error);
      api.error({
        message: 'Failed to update category',
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
        title={`Change Category for Ticket #${ticketId}`}
        open={visible}
        onCancel={onClose}
        footer={[
          <Button key="back" onClick={onClose}>
            Cancel
          </Button>,
          <Button key="submit" type="primary" loading={loading} onClick={handleSave}>
            Save
          </Button>,
        ]}
      >
        <Select
          loading={loading}
          style={{ width: '100%' }}
          placeholder="Select a new category"
          value={selectedCategory}
          onChange={setSelectedCategory}
          options={categories.map(cat => ({
            value: cat.id,
            label: cat.name,
          }))}
        />
      </Modal>
    </>
  );
}