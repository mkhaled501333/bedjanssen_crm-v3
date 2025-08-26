'use client';

import React, { useState, useMemo, useEffect, useCallback } from 'react';
import type { CustomerDataProps, CustomerTicket, TicketItem, CustomerDetails } from '../../types';
import { useCustomerData } from '../hooks/useCustomerData';
import styles from './CustomerData.module.css';
import { EditCustomerModal } from './modals/EditCustomerModal';
import { AddNewCallModal } from './modals/AddNewCallModal';
import { AddNewTicketModal } from './modals/AddNewTicketModal';
import { ChangeTicketCategoryModal } from './modals/ChangeTicketCategoryModal';
import { AddNewItemModal } from './modals/AddNewItemModal';
import { CloseTicketModal } from './modals/CloseTicketModal';
import { ViewAllCallsModal } from './modals/ViewAllCallsModal';
import { ActivityLogsModal } from './modals/ActivityLogsModal';
import { getCurrentUserCompanyId, getCurrentUserId } from '../../../../shared/utils/auth';
import { 
  updateCustomerDetails, 
  addCustomerCall, 
  addCustomerTicket, 
  closeTicket, 
  updateTicketCategory, 
  addTicketCall, 
  addTicketItem, 
  updateTicketItemInspection, 
  addMaintenance, 
  addChangeSame, 
  addChangeAnother, 
  deleteMaintenance, 
  deleteChangeSame, 
  deleteChangeAnother, 
  updateMaintenance, 
  updateChangeSame, 
  updateChangeAnother,
  updateTicketItem,
  deleteTicketItem
} from '../../api';
import { getCompanies, getProducts } from '../../../masterdata/api';
import { Company, Product } from '../../../masterdata/types';

type ActionType = 'maintenance' | 'change-same' | 'change-another' | null;

// To manage the state of the complex ticket item form
interface TicketItemState extends TicketItem {
  inspectionChecked?: boolean;
  inspectionDate?: string;
  inspectionResult?: string;
  selectedAction?: string;
  selectedActionType?: ActionType;
  actionFormData?: Record<string, unknown>;
  originalActionFormData?: Record<string, unknown>; // Track original data for change detection
}

const borderColors = [
  '#4299e1', '#48bb78', '#f56565', '#ed8936', '#805ad5', '#319795', '#d53f8c'
];

const backgroundColors = [
  '#f0f9ff', '#f0fff4', '#fff5f5', '#fffaf0', '#f9f5ff', '#effffb', '#fff5fa'
];

export function CustomerData({ customerId }: CustomerDataProps) {
  const { customer, isLoading, error, refreshCustomerData } = useCustomerData({ customerId });

  const [openTabs, setOpenTabs] = useState<string[]>(['all']);
  const [activeTab, setActiveTab] = useState<string>('all');
  const [expandedProducts, setExpandedProducts] = useState<Record<string, boolean>>({});
  const [ticketItemStates, setTicketItemStates] = useState<Record<string, TicketItemState>>({});
  const [isEditModalOpen, setEditModalOpen] = useState(false);
  const [isAddNewCallModalOpen, setAddNewCallModalOpen] = useState(false);
  const [isAddCallToTicketModalOpen, setIsAddCallToTicketModalOpen] = useState(false);
  const [isViewAllCallsModalOpen, setIsViewAllCallsModalOpen] = useState(false);
  const [isViewAllTicketCallsModalOpen, setIsViewAllTicketCallsModalOpen] = useState(false);
  const [isAddNewTicketModalOpen, setAddNewTicketModalOpen] = useState(false);
  const [isChangeCategoryModalOpen, setChangeCategoryModalOpen] = useState(false);
  const [isAddNewItemModalOpen, setAddNewItemModalOpen] = useState(false);
  const [isCloseTicketModalOpen, setIsCloseTicketModalOpen] = useState(false);
  const [selectedTicketForClose, setSelectedTicketForClose] = useState<string | null>(null);
  const [isClosingTicket, setIsClosingTicket] = useState(false);
  const [selectedTicketForCategoryChange, setSelectedTicketForCategoryChange] = useState<CustomerTicket | null>(null);
  const [products, setProducts] = useState<Product[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [dirtyResults, setDirtyResults] = useState<Record<string, boolean>>({});
  const [dirtyActionForms, setDirtyActionForms] = useState<Record<string, boolean>>({});
  const [isItemDirty, setIsItemDirty] = useState<Record<string, boolean>>({});
  const [isActionFormInvalid, setIsActionFormInvalid] = useState<Record<string, boolean>>({});
  const [isEditItemModalOpen, setIsEditItemModalOpen] = useState(false);
  const [isDeleteConfirmModalOpen, setIsDeleteConfirmModalOpen] = useState(false);
  const [selectedItemForEdit, setSelectedItemForEdit] = useState<TicketItemState | null>(null);
  const [selectedItemForDelete, setSelectedItemForDelete] = useState<{ ticketId: string; itemId: string; item: TicketItemState } | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isActivityLogsModalOpen, setIsActivityLogsModalOpen] = useState(false);
  const [selectedItemForActivities, setSelectedItemForActivities] = useState<string | null>(null);
  const [isTicketActivityLogsModalOpen, setIsTicketActivityLogsModalOpen] = useState(false);
  const [selectedTicketForActivities, setSelectedTicketForActivities] = useState<string | null>(null);
  const [isCustomerActivityLogsModalOpen, setIsCustomerActivityLogsModalOpen] = useState(false);


  const getCompanyName = (companyId: number) => {
    const company = companies.find(c => c.id === companyId);
    return company ? company.name : `ID: ${companyId}`;
  };

  const handleValidationChange = useCallback((key: string, isInvalid: boolean) => {
    setIsActionFormInvalid(prev => {
      if (prev[key] === isInvalid) {
        return prev;
      }
      return { ...prev, [key]: isInvalid };
    });
  }, []);

  // Helper function to get only changed fields
  const getChangedFields = (original: Record<string, unknown>, current: Record<string, unknown>): Record<string, unknown> => {
    const changes: Record<string, unknown> = {};
    
    // Check for changed or new fields
    Object.keys(current).forEach(key => {
      if (current[key] !== original[key]) {
        changes[key] = current[key];
      }
    });
    
    // Check for removed fields (set to null/undefined)
    Object.keys(original).forEach(key => {
      if (!(key in current) && original[key] !== undefined && original[key] !== null && original[key] !== '') {
        changes[key] = null;
      }
    });
    
    return changes;
  };

  useEffect(() => {
    // Initialize states for ticket items when customer data is loaded
    if (customer) {
      const initialStates: Record<string, TicketItemState> = {};
      customer.tickets.forEach(ticket => {
        ticket.ticketItems.forEach((item) => {
          const key = `${ticket.ticketID}-${item.id}`;
          const originalFormData = item.actionFormData || {};
          initialStates[key] = { 
            ...item, 
            inspectionChecked: item.inspected, 
            inspectionDate: item.inspectionDate, 
            inspectionResult: item.inspectionResult,
            selectedActionType: item.actionType,
            actionFormData: { ...originalFormData },
            originalActionFormData: { ...originalFormData }, // Store original data for comparison
          };
        });
      });
      setTicketItemStates(initialStates);
    }
  }, [customer]);

  useEffect(() => {
    const fetchMasterData = async () => {
        try {
            const [productList, companyList] = await Promise.all([
                getProducts(),
                getCompanies()
            ]);
            setProducts(productList);
            setCompanies(companyList);
        } catch {
            console.error("Failed to fetch master data");
        }
    };
    fetchMasterData();
  }, []);
  
  const handleSaveCustomer = async (updatedCustomer: CustomerDetails) => {
    if (!customer) return;

    try {
      await updateCustomerDetails(customer.id.toString(), {
        name: updatedCustomer.name,
        address: updatedCustomer.address,
        notes: updatedCustomer.notes,
        governorateId: updatedCustomer.governorateId,
        cityId: updatedCustomer.cityId,
      });
      refreshCustomerData();
      setEditModalOpen(false);
    } catch {
      // You might want to show an error message to the user
    }
  };
  const handleSaveCall = async (callData: {
    type: string;
    category: number;
    description: string;
    notes: string;
    minutes: string;
    seconds: string;
  }) => {
    if (!customer) return;

    const minutes = callData.minutes || '0';
    const seconds = callData.seconds || '0';
    const formattedDuration = `${minutes}:${seconds}`;

    // Get current user's company ID and user ID from authentication
    const companyId = getCurrentUserCompanyId();
    const userId = getCurrentUserId();
    
    if (!companyId || !userId) {
      console.error('User not authenticated or missing company/user information');
      return;
    }

    const newCallData = {
      companyId,
      callType: callData.type,
      categoryId: callData.category,
      description: callData.description,
      notes: callData.notes,
      callDuration: formattedDuration,
      createdBy: userId,
    };

    try {
      await addCustomerCall(customer.id.toString(), newCallData);
      setAddNewCallModalOpen(false);
      refreshCustomerData();
    } catch {
      // You might want to show an error message to the user
    }
  };

  const handleSaveCallToTicket = async (callData: {
    type: string;
    category: number;
    description: string;
    notes: string;
    minutes: string;
    seconds: string;
  }) => {
    if (!activeTicket) return;

    const minutes = callData.minutes || '0';
    const seconds = callData.seconds || '0';
    const formattedDuration = `${minutes}:${seconds}`;

    // Get current user's company ID and user ID from authentication
    const companyId = getCurrentUserCompanyId();
    const userId = getCurrentUserId();
    
    if (!companyId || !userId) {
      console.error('User not authenticated or missing company/user information');
      return;
    }

    const newCallData = {
      companyId,
      callType: callData.type,
      callCatId: callData.category,
      description: callData.description,
      callNotes: callData.notes,
      callDuration: formattedDuration,
      createdBy: userId,
    };

    try {
      await addTicketCall(activeTicket.ticketID.toString(), newCallData);
      setIsAddCallToTicketModalOpen(false);
      refreshCustomerData();
    } catch {
      // You might want to show an error message to the user
    }
  };

  const handleSaveTicket = async (ticketData: Record<string, unknown>) => {
    if (!customer) return;

    // Get current user's company ID and user ID from authentication
    const companyId = getCurrentUserCompanyId();
    const userId = getCurrentUserId();
    
    if (!companyId || !userId) {
      console.error('User not authenticated or missing company/user information');
      return;
    }
    const call = ticketData.call as {
      callType: string;
      callCatId: number;
      description: string;
      callNotes: string;
      callDuration: string;
    };
    const item = ticketData.item as {
      productId: number;
      quantity: number;
      productSize: string;
      purchaseDate: string;
      purchaseLocation: string;
      requestReasonId: number;
      requestReasonDetail: string;
    };
    const newTicketData = {
      companyId,
      customerId: customer.id,
      ticketCatId: ticketData.ticketCatId,
      description: ticketData.description,
      status: ticketData.status || 'open',
      priority: ticketData.priority || 'medium',
      createdBy: userId,
      call: {
        callType: call.callType,
        callCatId: call.callCatId,
        description: call.description,
        callNotes: call.callNotes,
        callDuration: call.callDuration,
      },
      item: {
        productId: item.productId,
        quantity: item.quantity,
        productSize: item.productSize,
        purchaseDate: item.purchaseDate,
        purchaseLocation: item.purchaseLocation,
        requestReasonId: item.requestReasonId,
        requestReasonDetail: item.requestReasonDetail,
      }
    };

    try {
      await addCustomerTicket(newTicketData);
      setAddNewTicketModalOpen(false);
      refreshCustomerData();
    } catch {
      console.error("Failed to add ticket");
      // You might want to show an error message to the user
    }
  };

  const handleSaveTicketItem = async (itemData: Record<string, unknown>) => {
    if (!activeTicket) return;
    // Cast itemData to the expected type
    const castedItemData = itemData as {
      companyId: number;
      productId: number;
      quantity: number;
      createdBy: number;
      product_size?: string;
      purchase_date: string;
      purchase_location?: string;
      request_reason_id: number;
      request_reason_detail?: string;
    };
    try {
      await addTicketItem(activeTicket.ticketID.toString(), castedItemData);
      setAddNewItemModalOpen(false);
      refreshCustomerData();
    } catch {

        console.error("Failed to add ticket item: " + String(error));
      
      // You might want to show an error message to the user
    }
  };

  const handleCloseTicket = (ticketId: string) => {
    setSelectedTicketForClose(ticketId);
    setIsCloseTicketModalOpen(true);
  };

  const handleConfirmCloseTicket = async (notes: string) => {
    if (!selectedTicketForClose) return;
    
    // Get current user ID from authentication
    const userId = getCurrentUserId();
    
    if (!userId) {
      console.error('User not authenticated');
      return;
    }

    setIsClosingTicket(true);
    
    try {
      await closeTicket(selectedTicketForClose, notes, userId);
      refreshCustomerData();
      setIsCloseTicketModalOpen(false);
      setSelectedTicketForClose(null);
      // Switch back to the main tab after closing
      setActiveTab('all');
    } catch {
      console.error("Failed to close ticket");
      // You might want to show an error message to the user
    } finally {
      setIsClosingTicket(false);
    }
  };

  const handleCloseTicketModalClose = () => {
    if (!isClosingTicket) {
      setIsCloseTicketModalOpen(false);
      setSelectedTicketForClose(null);
    }
  };

  const handleOpenChangeCategoryModal = (ticket: CustomerTicket) => {
    setSelectedTicketForCategoryChange(ticket);
    setChangeCategoryModalOpen(true);
  };

  const handleUpdateTicketCategory = async (newCategoryId: number) => {
    if (!selectedTicketForCategoryChange) return;
  
    try {
      await updateTicketCategory(selectedTicketForCategoryChange.ticketID.toString(), newCategoryId);
      refreshCustomerData();
      setChangeCategoryModalOpen(false); // Close modal on success
    } catch {
      console.error("Failed to update ticket category");
      // The modal will show its own error notification
      throw error; // Re-throw to let the modal handle its loading state
    }
  };

  const handleActionTypeChange = async (key: string, newActionType: ActionType) => {
    const itemState = ticketItemStates[key];
    if (!itemState) return;

    const [, itemIdStr] = key.split('-');
    const itemId = parseInt(itemIdStr, 10);
    if (!itemId) return;

    const currentActionType = itemState.selectedActionType;
    
    // Get current user's company ID and user ID from authentication
    const companyId = getCurrentUserCompanyId();
    const userId = getCurrentUserId();
    
    if (!companyId || !userId) {
      console.error('User not authenticated or missing company/user information');
      return;
    }
    
    const commonData = { companyId, createdBy: userId };

    // Helper to delete an action
    const deleteAction = async (actionToDelete: ActionType) => {
        if (!actionToDelete) return;
        try {
            switch (actionToDelete) {
                case 'maintenance': await deleteMaintenance(itemId.toString()); break;
                case 'change-same': await deleteChangeSame(itemId.toString()); break;
                case 'change-another': await deleteChangeAnother(itemId.toString()); break;
            }
        } catch (e) {
            console.error("Failed to delete action", e);
            throw e;
        }
    };
    
    // Helper to add an action
    const addAction = async (actionToAdd: ActionType) => {
        if (!actionToAdd) return;
        try {
            switch (actionToAdd) {
                case 'maintenance': await addMaintenance(itemId.toString(), commonData); break;
                case 'change-same': await addChangeSame(itemId.toString(), { ...commonData, productId: itemState.productId }); break;
                case 'change-another': await addChangeAnother(itemId.toString(), commonData); break;
            }
        } catch (e) {
            console.error('Failed to create new action record', e);
            throw e;
        }
    };
    
    // Case 1: Clicking the same action to deselect it
    if (newActionType === currentActionType) {
        if (window.confirm("This will remove the current selected action. Are you sure?")) {
            try {
                await deleteAction(currentActionType);
                updateTicketItemState(key, { selectedActionType: null, actionFormData: {}, originalActionFormData: {} });
                setDirtyActionForms(prev => ({ ...prev, [key]: false }));
            } catch {
                // Optionally show an error notification to the user
            }
        }
    } 
    // Case 2: Switching from one action to another
    else if (currentActionType) {
        if (window.confirm("This will replace the current action. Are you sure?")) {
            try {
                await deleteAction(currentActionType);
                await addAction(newActionType);
                updateTicketItemState(key, { selectedActionType: newActionType, actionFormData: {}, originalActionFormData: {} });
                setDirtyActionForms(prev => ({ ...prev, [key]: false }));
            } catch {
                // Optionally show an error notification to the user
            }
        }
    } 
    // Case 3: Selecting an action for the first time
    else {
        try {
            await addAction(newActionType);
            updateTicketItemState(key, { selectedActionType: newActionType, actionFormData: {}, originalActionFormData: {} });
            setDirtyActionForms(prev => ({ ...prev, [key]: false }));
        } catch {
            // Optionally show an error notification to the user
        }
    }
  };
  
  const handleActionFormChange = (key: string, field: string, value: unknown) => {
    const itemState = ticketItemStates[key];
    // Cast value to the expected type for form fields
    const newFormData = { ...itemState.actionFormData, [field]: value as string | number | boolean };

    if (field === 'brandId') {
      newFormData.productId = '';
    }

    updateTicketItemState(key, { actionFormData: newFormData });
    setDirtyActionForms(prev => ({ ...prev, [key]: true }));
    setIsItemDirty(prev => ({ ...prev, [key]: true }));
  };

  const handleSaveActionForm = async (key: string) => {
    const itemState = ticketItemStates[key];
    if (!itemState || !itemState.selectedActionType || !itemState.actionFormData) return;

    const { selectedActionType, actionFormData, originalActionFormData } = itemState;

    // Validation for 'change-another'
    if (selectedActionType === 'change-another') {
      if (!actionFormData.brandId || !actionFormData.productId) {
        alert('Please select both a brand and a new product.');
        return;
      }
    }

    const [, itemIdStr] = key.split('-');
    const itemId = parseInt(itemIdStr, 10);
    
    // Get only the changed fields
    const originalData = originalActionFormData || {};
    const changedFields = getChangedFields(originalData, actionFormData);
    
    // If no changes, don't send request
    if (Object.keys(changedFields).length === 0) {
      console.log('No changes detected, skipping API call');
      setDirtyActionForms(prev => ({ ...prev, [key]: false }));
      return;
    }
    
    const dataToSend = { ...changedFields };

    if (selectedActionType === 'change-another' && dataToSend.brandId) {
      dataToSend.companyId = parseInt(String(dataToSend.brandId), 10);
      delete dataToSend.brandId;
    }

    if (itemId) {
      try {
        switch (selectedActionType) {
          case 'maintenance':
            await updateMaintenance(itemId.toString(), dataToSend);
            break;
          case 'change-same':
            await updateChangeSame(itemId.toString(), dataToSend);
            break;
          case 'change-another':
            await updateChangeAnother(itemId.toString(), dataToSend);
            break;
        }
        
        // Update the original data to reflect the new saved state
        setTicketItemStates(prev => ({
          ...prev,
          [key]: {
            ...prev[key],
            originalActionFormData: { ...actionFormData }
          }
        }));
        
        setDirtyActionForms(prev => ({ ...prev, [key]: false }));
        console.log('Action updated successfully with changed fields:', Object.keys(changedFields));
      } catch {
        console.error('Failed to update action');
      }
    }
  };

  const handleSaveItemChanges = async (key: string) => {
    if (dirtyResults[key]) {
      await handleSaveInspectionResult(key);
    }
    if (dirtyActionForms[key]) {
      await handleSaveActionForm(key);
    }
    setIsItemDirty(prev => ({ ...prev, [key]: false }));
  };

  const handleSaveInspectionResult = async (key: string) => {
    const itemState = ticketItemStates[key];
    if (!itemState) return;

    const [, itemIdStr] = key.split('-');
    const itemId = parseInt(itemIdStr, 10);

    if (itemId) {
      try {
        await updateTicketItemInspection(itemId.toString(), {
          inspectionResult: itemState.inspectionResult,
        });
        setDirtyResults(prev => ({ ...prev, [key]: false })); // Hide button on success
      } catch {
        // You might want to show an error message to the user
      }
    }
  };

  const updateTicketItemState = (key: string, newState: Partial<TicketItemState>) => {
    const currentState = ticketItemStates[key];

    // Handle unchecking with confirmation
    if (newState.inspectionChecked === false) {
        const confirmed = window.confirm("Are you sure you want to unmark this item as inspected? This will clear the inspection date and result.");
        if (!confirmed) {
            return; // Abort the update if user cancels
        }
        
        // If confirmed, create the state for clearing the data
        const clearedState = { 
            ...currentState, 
            inspectionChecked: false, 
            inspectionDate: undefined, 
            inspectionResult: '' 
        };

        setTicketItemStates(prev => ({ ...prev, [key]: clearedState }));

        // Update the backend to clear the data
        const [, itemIdStr] = key.split('-');
        const itemId = parseInt(itemIdStr, 10);
        if (itemId) {
            updateTicketItemInspection(itemId.toString(), {
                inspected: false,
                inspectionDate: undefined,
                inspectionResult: ''
            });
        }
        return; // End the function here for the un-check case
    }

    // For changes to the inspection result, just mark it as dirty
    if (newState.inspectionResult !== undefined) {
      setTicketItemStates(prev => ({ ...prev, [key]: { ...prev[key], ...newState } }));
      setDirtyResults(prev => ({ ...prev, [key]: true }));
      setIsItemDirty(prev => ({ ...prev, [key]: true }));
      return;
    }

    // For all other cases (checking the box, changing date/result)
    const updatedState = { ...currentState, ...newState };
    setTicketItemStates(prev => ({ ...prev, [key]: updatedState }));

    // Trigger backend update only if relevant fields have changed
    if (newState.inspectionDate !== undefined || newState.inspectionChecked === true) {
      const [, itemIdStr] = key.split('-');
      const itemId = parseInt(itemIdStr, 10);
      if (itemId) {
        // This could be debounced in a real app, but for now we'll call it directly
        // Send only the specific field that was changed
        if (newState.inspectionChecked === true) {
          updateTicketItemInspection(itemId.toString(), {
            inspected: true
          });
        }
        if (newState.inspectionDate !== undefined) {
          updateTicketItemInspection(itemId.toString(), {
            inspectionDate: updatedState.inspectionDate
          });
        }
      }
    }
  };

  const activeTicket = useMemo(() => {
    if (activeTab === 'all' || !customer) return null;
    return customer.tickets.find(t => t.ticketID.toString() === activeTab) || null;
  }, [activeTab, customer]);

  const formatDate = (dateString: string) => {
    if (!dateString) return 'N/A';
    // Extract only the date part (YYYY-MM-DD)
    if (dateString.includes(' ')) {
      return dateString.split(' ')[0]; // Get only the date part before space
    }
    if (dateString.includes('T')) {
      return dateString.split('T')[0]; // Handle ISO format
    }
    return dateString;
  };

  const formatDateTime = (dateString: string) => {
    if (!dateString) return 'N/A';
    // Display the raw date string as received from database
    return dateString;
  }
  
  const formatTime = (dateString: string) => {
    if (!dateString) return 'N/A';
    // Extract only the time part (HH:MM)
    if (dateString.includes(' ') && dateString.includes(':')) {
      const timePart = dateString.split(' ')[1]; // Get time part after space
      return timePart.substring(0, 5); // Keep only HH:MM
    }
    if (dateString.includes('T') && dateString.includes(':')) {
      const timePart = dateString.split('T')[1]; // Handle ISO format
      return timePart.substring(0, 5); // Keep only HH:MM
    }
    return dateString;
  };

  const formatShortDate = (dateString: string) => {
    if (!dateString) return 'N/A';
    const d = new Date(dateString);
    const day = d.getDate().toString().padStart(2, '0');
    const month = (d.getMonth() + 1).toString().padStart(2, '0');
    const year = d.getFullYear();
    return `${day}/${month}/${year}`;
  }

  const formatDateForInput = (dateString?: string) => {
    if (!dateString) return '';
    try {
        return new Date(dateString).toISOString().split('T')[0];
    } catch {
        return '';
    }
  };

  const switchToTab = (ticketId: string) => {
    if (!openTabs.includes(ticketId)) {
      setOpenTabs(prev => [...prev, ticketId]);
    }
    setActiveTab(ticketId);
  };

  const closeTab = (e: React.MouseEvent, ticketId: string) => {
    e.stopPropagation();
    if (ticketId === 'all' || openTabs.length <= 1) return;
    
    setOpenTabs(tabs => tabs.filter(t => t !== ticketId));
    if (activeTab === ticketId) {
      setActiveTab('all');
    }
  };

  const toggleProductCollapse = (key: string) => {
    setExpandedProducts(prev => ({ ...prev, [key]: !prev[key] }));
  };

  const handleEditItem = (ticketId: string, item: TicketItemState) => {
    const selectedItem = { 
      ...item, 
      ticketID: parseInt(ticketId),
      companyId: item.companyId || 0
    };

    setSelectedItemForEdit(selectedItem);
    setIsEditItemModalOpen(true);
  };

  const handleDeleteItem = (ticketId: string, itemId: string, item: TicketItemState) => {
    setSelectedItemForDelete({ ticketId, itemId, item });
    setIsDeleteConfirmModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!selectedItemForDelete) return;
    
    setIsDeleting(true);
    try {
      await deleteTicketItem(selectedItemForDelete.ticketId, selectedItemForDelete.itemId);
      refreshCustomerData();
      setIsDeleteConfirmModalOpen(false);
      setSelectedItemForDelete(null);
    } catch (error) {
      console.error('Failed to delete ticket item:', error);
      alert('Failed to delete item. Please try again.');
    } finally {
      setIsDeleting(false);
    }
  };

  const handleUpdateItem = async (itemData: {
    productId?: number;
    quantity?: number;
    product_size?: string;
    purchase_date?: string;
    purchase_location?: string;
    request_reason_id?: number;
    request_reason_detail?: string;
  }) => {
    if (!selectedItemForEdit) return;
    
    try {
      await updateTicketItem(
        selectedItemForEdit.ticketID.toString(),
        selectedItemForEdit.id.toString(),
        itemData
      );
      refreshCustomerData();
      setIsEditItemModalOpen(false);
      setSelectedItemForEdit(null);
    } catch (error) {
      console.error('Failed to update ticket item:', error);
      alert('Failed to update item. Please try again.');
    }
  };

  if (isLoading) {
    return <div className={styles.container}><p>Loading...</p></div>;
  }

  if (error) {
    return <div className={styles.container}><p>Error: {error}</p></div>;
  }

  if (!customer) {
    return <div className={styles.container}><p>Customer not found.</p></div>;
  }

  return (
    <div className={styles.container}>
      {isChangeCategoryModalOpen && selectedTicketForCategoryChange && (
        <ChangeTicketCategoryModal
          visible={isChangeCategoryModalOpen}
          onClose={() => setChangeCategoryModalOpen(false)}
          onSave={handleUpdateTicketCategory}
          currentCategoryId={selectedTicketForCategoryChange.ticketCatId}
          ticketId={selectedTicketForCategoryChange.ticketID}
        />
      )}
      {isAddNewTicketModalOpen && customer && (
        <AddNewTicketModal
          customerName={customer.name}
          customerId={customer.id}
          onClose={() => setAddNewTicketModalOpen(false)}
          onSave={handleSaveTicket}
        />
      )}
      {isAddNewItemModalOpen && activeTicket && (
        <AddNewItemModal
          ticketId={activeTicket.ticketID}
          onClose={() => setAddNewItemModalOpen(false)}
          onSave={handleSaveTicketItem}
        />
      )}
      {isAddNewCallModalOpen && (
        <AddNewCallModal
          onClose={() => setAddNewCallModalOpen(false)}
          onSave={handleSaveCall}
        />
      )}
       {isAddCallToTicketModalOpen && (
        <AddNewCallModal
          onClose={() => setIsAddCallToTicketModalOpen(false)}
          onSave={handleSaveCallToTicket}
        />
      )}
      {isViewAllCallsModalOpen && customer && (
        <ViewAllCallsModal
          onClose={() => setIsViewAllCallsModalOpen(false)}
          calls={customer.calls.map(call => ({
            ...call,
            id: call.id.toString()
          }))}
          getCompanyName={getCompanyName}
          customerId={customer.id}
          companyId={customer.companyId}
        />
      )}
      {isViewAllTicketCallsModalOpen && activeTicket && (
        <ViewAllCallsModal
          onClose={() => setIsViewAllTicketCallsModalOpen(false)}
          calls={(activeTicket.calls || []).map(call => ({
            ...call,
            id: call.id.toString()
          }))}
          getCompanyName={getCompanyName}
          customerId={customer?.id || 0}
          companyId={customer?.companyId || 0}
        />
      )}
      {isEditModalOpen && customer && (
        <EditCustomerModal
          customer={customer}
          onClose={() => setEditModalOpen(false)}
          onSave={handleSaveCustomer}
          onDataChange={refreshCustomerData}
        />
      )}
      {isCloseTicketModalOpen && selectedTicketForClose && (
        <CloseTicketModal
          isOpen={isCloseTicketModalOpen}
          onClose={handleCloseTicketModalClose}
          onConfirm={handleConfirmCloseTicket}
          ticketId={selectedTicketForClose}
          isLoading={isClosingTicket}
        />
      )}
      {isEditItemModalOpen && selectedItemForEdit && (
        <AddNewItemModal
          ticketId={selectedItemForEdit.ticketID || 0}
          onClose={() => {
            setIsEditItemModalOpen(false);
            setSelectedItemForEdit(null);
          }}
          onSave={handleUpdateItem}
          editMode={true}
          initialValues={(() => {
            const initialVals = {
              id: selectedItemForEdit.id,
              companyId: selectedItemForEdit.companyId,
              productId: selectedItemForEdit.productId,
              quantity: selectedItemForEdit.quantity,
              product_size: selectedItemForEdit.productSize,
              purchase_date: selectedItemForEdit.purchaseDate,
              purchase_location: selectedItemForEdit.purchaseLocation,
              request_reason_id: selectedItemForEdit.requestReasonId,
              request_reason_detail: selectedItemForEdit.requestReasonDetail
            };
            
            return initialVals;
          })()
          }
        />
      )}
      {isDeleteConfirmModalOpen && selectedItemForDelete && (
        <div className={styles.modalOverlay}>
          <div className={styles.modal}>
            <div className={styles.modalHeader}>
              <h3>Confirm Delete</h3>
            </div>
            <div className={styles.modalContent}>
              <p>Are you sure you want to delete this item?</p>
              <div className={styles.itemDetails}>
                <p><strong>Product:</strong> {selectedItemForDelete.item.productName}</p>
                <p><strong>Size:</strong> {selectedItemForDelete.item.productSize}</p>
                <p><strong>Quantity:</strong> {selectedItemForDelete.item.quantity}</p>
              </div>
              <p style={{ color: '#d32f2f', fontWeight: 'bold' }}>This action cannot be undone.</p>
            </div>
            <div className={styles.modalActions}>
              <button 
                className={styles.cancelButton}
                onClick={() => {
                  setIsDeleteConfirmModalOpen(false);
                  setSelectedItemForDelete(null);
                }}
                disabled={isDeleting}
              >
                Cancel
              </button>
              <button 
                className={styles.deleteConfirmButton}
                onClick={handleConfirmDelete}
                disabled={isDeleting}
              >
                {isDeleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
      {isActivityLogsModalOpen && selectedItemForActivities && (
        <ActivityLogsModal
          onClose={() => {
            setIsActivityLogsModalOpen(false);
            setSelectedItemForActivities(null);
          }}
          itemId={parseInt(selectedItemForActivities)}
        />
      )}
      {isTicketActivityLogsModalOpen && selectedTicketForActivities && (
        <ActivityLogsModal
          onClose={() => {
            setIsTicketActivityLogsModalOpen(false);
            setSelectedTicketForActivities(null);
          }}
          ticketId={parseInt(selectedTicketForActivities)}
        />
      )}
      {isCustomerActivityLogsModalOpen && (
        <ActivityLogsModal
          onClose={() => {
            setIsCustomerActivityLogsModalOpen(false);
          }}
          customerId={customer.id}
        />
      )}
      {/* Sidebar */}
      <div className={styles.sidebar}>
        <div className={styles.customerDetailsSection}>
          <div className={styles.customerInfo}>
            <div className={styles.customerName}>{customer.name}</div>
            <div className={styles.customerIndicators}>
              <div className={styles.indicatorItem} onClick={() => setEditModalOpen(true)}><span>✏️</span></div>
              <div className={styles.indicatorItem}><span>{getCompanyName(customer.companyId)}</span></div>
              <div className={styles.indicatorItem}><span>ID: {customer.id}</span></div>
              <div className={styles.indicatorItem} onClick={() => setIsCustomerActivityLogsModalOpen(true)}><span>⚙️</span></div>
            </div>
            <div className={styles.phoneList}>
              {customer.phones.map((phone) => (
                <div key={phone.id} className={styles.phoneItem}>
                  <div className={styles.phoneContent}>
                    <div className={styles.phoneIcon}>📞</div>
                    <span className={styles.phoneNumber}>{phone.phone}</span>
                  </div>
                </div>
              ))}
            </div>
            <div className={styles.addressSection}>
              <div className={styles.addressHeader}>
                <div className={styles.addressIcon}>🌍</div>
                <div className={styles.addressTitle}>{customer.governorate}</div>
                <div className={styles.addressIcon}>💼</div>
                <div className={styles.addressTitle}>{customer.city}</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                <div className={styles.addressIcon}>📍</div>
              </div>
              <div className={styles.addressText}>{customer.address || 'No address provided'}</div>
            </div>
          </div>
        </div>
        <div className={styles.customerCallsSection}>
          <div className={styles.callsHeader}>
            <h3>📞 <span className={styles.callCounter}>({customer.calls.length})</span> Customer Calls</h3>
            <div className={styles.callsHeaderButtons}>
              <button className={styles.addCallButton} onClick={() => setAddNewCallModalOpen(true)}>إضافة</button>
              <button className={styles.viewAllCallsButton} onClick={() => setIsViewAllCallsModalOpen(true)}>عرض الكل</button>
            </div>
          </div>
          <div className={styles.callsList}>
            {customer.calls.map((call, index) => (
              <div key={call.id} className={styles.callItem}>
                <div className={styles.callHeader}>
                  <div className={styles.callTypeBadge}>
                    <div className={`${styles.callType} ${call.callType === '0' ? styles.incoming : styles.outgoing}`}>
                      <span role="img" aria-label={call.callType === '0' ? "Incoming call" : "Outgoing call"}>
                        {call.callType === '0' ? '↙️' : '↗️'}
                      </span>
                      {call.callType === '0' ? 'Incoming' : 'Outgoing'}
                    </div>
                  </div>
                  <div className={styles.callDate}>{formatDate(call.createdAt)}</div>
                  <div className={styles.callTime}>{formatTime(call.createdAt)}</div>
                  <div className={styles.callNumber}>#{index + 1}</div>
                </div>
                <div className={styles.callMainInfo}>
                  <div className={styles.callAgent}>👤 {call.createdBy}</div>
                  <div className={styles.callCompany}>🏢 {getCompanyName(customer.companyId)}</div>
                </div>
                <div className={styles.callCategoryWrapper}>
                  <div className={styles.callCategory}>{call.category}</div>
                </div>
                <div className={styles.callFooter}>
                  <div className={styles.callDuration}>⏱️ {call.callDuration}</div>
                </div>
              </div>
            ))}
            <div className={styles.scrollSpacer}></div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className={styles.mainContent}>
        <div className={styles.ticketsFilter}>
          {openTabs.map(ticketId => {
            const ticket = customer.tickets.find(t => t.ticketID.toString() === ticketId);
            const statusText = ticket ? (ticket.status == 0 ? 'OPEN' : 'CLOSED') : '';
            const statusClass = ticket ? (ticket.status == 0 ? styles.statusOpen : styles.statusSolved) : '';

            return (
              <div key={ticketId}
                className={`${styles.filterTab} ${activeTab === ticketId ? styles.active : ''}`}
                onClick={() => switchToTab(ticketId)}>
                <span>
                  {ticketId === 'all'
                    ? 'All Tickets'
                    : `#${ticketId}`}
                  {ticketId === 'all' && (
                    <span className={styles.ticketCountBadge}>
                      {customer.tickets.length}
                    </span>
                  )}
                </span>
                {ticketId !== 'all' && ticket && (
                  <span className={`${styles.ticketStatus} ${statusClass}`} style={{ marginLeft: '8px', padding: '2px 6px', borderRadius: '4px', fontSize: '10px' }}>
                    {statusText}
                  </span>
                )}
                {ticketId !== 'all' && (
                  <div className={styles.tabClose} onClick={(e) => closeTab(e, ticketId)}>&times;</div>
                )}
              </div>
            );
          })}
          <button className={styles.addNewTicketButton} onClick={() => setAddNewTicketModalOpen(true)}>+ New Ticket</button>
        </div>

        <div className={styles.contentArea} style={{ padding: 0, overflow: 'visible', display: 'flex', flexDirection: 'column' }}>
          {activeTab === 'all' ? (
            <div className={styles.ticketsList} style={{ padding: '20px' }}>
              {customer.tickets.map(ticket => (
                <div key={ticket.ticketID} className={styles.ticketItem} onClick={() => ticket.ticketID && switchToTab(ticket.ticketID.toString())}>
                  <div className={styles.ticketTopRow}>
                    <div className={styles.ticketStatusAndId}>
                      <div className={`${styles.ticketStatus} ${ticket.status == 0 ? styles.statusOpen : styles.statusSolved}`}>
                        {ticket.status == 0 ? 'OPEN' : 'CLOSED'}
                      </div>
                      <div className={styles.ticketId}>#{ticket.ticketID}</div>
                    </div>
                    <div className={styles.ticketDateWrapper}>
                      <span className={styles.ticketDate}>{formatDateTime(ticket.createdAt)}</span>
                      <span className={styles.editIcon}>✏️</span>
                    </div>
                  </div>
                  <div className={styles.ticketCompanyId}>{ticket.companyId}</div>
                  <div className={styles.ticketBottomRow}>
                    <div className={styles.creatorInfo}>
                      <div className={styles.avatar}>{ticket.createdBy?.charAt(0).toUpperCase()}</div>
                      <div className={styles.creatorDetails}>
                        <span className={styles.raisedBy}>raised by</span>
                        <span className={styles.creatorName}>{ticket.createdBy}</span>
                      </div>
                    </div>
                    <div className={styles.ticketDetailsGroup}>
                      <div className={styles.infoItem}>
                        <span className={styles.infoLabel}>priority</span>
                        <span className={styles.infoValue}>{ticket.priority}</span>
                      </div>
                      <div className={styles.infoItem}>
                        <span className={styles.infoLabel}>category</span>
                        <span className={styles.infoValue}>{ticket.ticketCat}</span>
                      </div>
                       <div className={styles.infoItem}>
                        <span className={styles.infoLabel}>Company</span>
                        <span className={styles.infoValue}>{getCompanyName(ticket.companyId)}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className={styles.ticketDetailView}>
              {activeTicket && (
                <div className={styles.ticketDetailContainer}>
                  <div className={styles.ticketDetailMain}>
                    <div className={styles.ticketStaticHeader}>
                        <div className={styles.headerVisualContainer}>
                            <div className={styles.headerIconSection}><div className={styles.mainIcon}>🎫</div></div>
                            <div className={styles.headerInfoSection}>
                                <span className={styles.ticketNumber}>#{activeTicket.ticketID}</span>
                                <span className={styles.ticketType}>تفاصيل التذكرة</span>
                            </div>
                        </div>
                    </div>
                    <div className={styles.ticketCategoryBadge}>
                        <span className={styles.badgeIcon}>▲</span>
                        <span className={styles.badgeText}>{activeTicket.ticketCat}</span>
                        <button 
                          className={styles.badgeEditBtn} 
                          title={activeTicket.status === 1 ? "Cannot edit category of closed ticket" : "Edit Category"}
                          onClick={() => handleOpenChangeCategoryModal(activeTicket)}
                          disabled={activeTicket.status === 1}
                        >
                          ✏️
                        </button>
                    </div>
                    <div className={styles.ticketDetailsStatic}>
                        <div className={styles.ticketDetailsGrid}>
                            <div className={styles.detailItem}><label>Created Date</label><span>{formatShortDate(activeTicket.createdAt)}</span></div>
                            <div className={styles.detailItem}><label>Created By</label><span>{activeTicket.createdBy || 'Unknown User'}</span></div>
                            <div className={styles.detailItem}><label>Category</label><span>{activeTicket.ticketCat}</span></div>
                            <div className={styles.detailItem}><label>Company</label><span>{getCompanyName(activeTicket.companyId)}</span></div>
                        </div>
                        <div className={styles.ticketActionsStatic}>
                            {activeTicket.status === 1 && (
                                <div className={styles.closedTicketNotice}>
                                    <span>⚠️ This ticket is closed and is read-only</span>
                                </div>
                            )}
                            <div className={styles.ticketActionButtons}>
                              <button 
                                className={styles.activityLogsBtn}
                                onClick={() => {
                                  setSelectedTicketForActivities(activeTicket.ticketID.toString());
                                  setIsTicketActivityLogsModalOpen(true);
                                }}
                                title="View ticket activities"
                              >
                                📋 Activities
                              </button>
                              <button 
                                className={styles.closeTicketBtn} 
                                onClick={() => handleCloseTicket(activeTicket.ticketID.toString())}
                                disabled={activeTicket.status === 1}
                                title={activeTicket.status === 1 ? 'Ticket is already closed' : 'Close this ticket'}
                              >
                                {activeTicket.status === 0 ? '✓ Close Ticket' : 'Ticket Closed'}
                              </button>
                            </div>
                        </div>
                    </div>
                     <div className={styles.callLogSection}>
                        <div className={styles.callLogHeader}>
                            <h3>📞 #{activeTicket.ticketID} Call Log</h3>
                            <div className={styles.callsHeaderButtons}>
                              <button 
                            className={styles.addCallButton} 
                            onClick={() => setIsAddCallToTicketModalOpen(true)}
                            disabled={activeTicket.status === 1}
                            title={activeTicket.status === 1 ? 'Cannot add calls to closed ticket' : 'Add a new call'}
                          >
                            إضافة
                          </button>
                              <button 
                            className={styles.viewAllCallsButton} 
                            onClick={() => setIsViewAllTicketCallsModalOpen(true)}
                            title="View all ticket calls"
                          >
                            عرض الكل
                          </button>
                            </div>
                            <span className={styles.callCount}>{activeTicket.calls?.length || 0}</span>
                        </div>
                        <div className={styles.callEntriesScrollable}>
                           {activeTicket.calls?.map((call, index) => (
                             <div key={call.id} className={styles.callItem}>
                               <div className={styles.callHeader}>
                                 <div className={styles.callTypeBadge}>
                                   <div className={`${styles.callType} ${call.callType === '0' ? styles.incoming : styles.outgoing}`}>
                                     <span role="img" aria-label={call.callType === '0' ? "Incoming call" : "Outgoing call"}>
                                       {call.callType === '0' ? '↙️' : '↗️'}
                                     </span>
                                     {call.callType === '0' ? 'Incoming' : 'Outgoing'}
                                   </div>
                                 </div>
                                 <div className={styles.callDate}>{formatDate(call.createdAt)}</div>
                                 <div className={styles.callTime}>{formatTime(call.createdAt)}</div>
                                 <div className={styles.callNumber}>#{index + 1}</div>
                               </div>
                               <div className={styles.callMainInfo}>
                                 <div className={styles.callAgent}>👤 {call.createdBy}</div>
                                 <div className={styles.callCompany}>🏢 {getCompanyName(customer.companyId)}</div>
                               </div>
                               <div className={styles.callCategoryWrapper}>
                                 <div className={styles.callCategory}>{call.category}</div>
                               </div>
                               <div className={styles.callFooter}>
                                 <div className={styles.callDuration}>⏱️ {call.callDuration}</div>
                               </div>
                             </div>
                           ))}
                           <div className={styles.scrollSpacer}></div>
                        </div>
                    </div>
                  </div>
                  <div className={styles.ticketDetailSidebar}>
                     <div className={styles.sidebarStaticHeader}>
                         <div className={styles.headerVisualContainer}>
                            <div className={styles.headerInfoSection}>
                                <span className={styles.sidebarTitleStrong}>#{activeTicket.ticketID}</span>
                                <span>Ticket Items</span>
                                <span className={styles.countIndicator} style={{background: '#4299e1', color: '#fff', padding: '2px 10px', borderRadius: '12px', fontSize: '15px', fontWeight: 700}}>{activeTicket.ticketItems.length}</span>
                            </div>
                                                                        <button 
                                              className={styles.addCallButton} 
                                              onClick={() => setAddNewItemModalOpen(true)}
                                              disabled={activeTicket.status === 1}
                                              title={activeTicket.status === 1 ? 'Cannot add items to closed ticket' : 'Add a new item'}
                                            >
                                              إضافة
                                            </button>
                         </div>
                     </div>
                     <div className={styles.sidebarContent}>
                        {activeTicket.ticketItems.map((item, index) => {
                          const key = `${activeTicket.ticketID}-${item.id}`;
                          const isExpanded = !!expandedProducts[key];
                          const itemState = ticketItemStates[key];
                          
                          // If state for this item is not ready, don't render it.
                          if (!itemState) {
                            return null;
                          }

                          const borderColor = borderColors[index % borderColors.length];
                          const backgroundColor = backgroundColors[index % backgroundColors.length];
                          
                          const containerStyle: React.CSSProperties = { 
                            backgroundColor
                          };

                          if (isExpanded) {
                            containerStyle.borderColor = borderColor;
                            containerStyle.boxShadow = `0 4px 12px 0 ${borderColor}50`;
                          }

                          return (
                            <div key={key} className={styles.productInfoContainer} style={containerStyle}>
                              <div className={`${styles.productHeader} ${isExpanded ? styles.productHeaderExpanded : ''}`} onClick={() => toggleProductCollapse(key)}>
                                <div className={styles.productHeaderContent}>
                                    <div className={styles.productHeaderIndex}>{index + 1}</div>
                                    <div className={styles.productHeaderGrid}>
                                        <div className={styles.productInfoColumn}>
                                            <span className={styles.productHeaderLabel}>Company</span>
                                            <span className={styles.productHeaderText}>{item.productBrand || getCompanyName(customer.companyId)}</span>
                                        </div>
                                        <div className={styles.productInfoColumn}>
                                            <span className={styles.productHeaderLabel}>Product Name</span>
                                            <span className={styles.productHeaderText}>{item.productName}</span>
                                        </div>
                                        <div className={styles.productInfoColumn}>
                                            <span className={styles.productHeaderLabel}>QTY</span>
                                            <span className={styles.productHeaderText}>{item.quantity}</span>
                                        </div>
                                    </div>
                                    <div className={`${styles.collapseBtn} ${!isExpanded ? styles.collapsed : ''}`}>
                                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M7 10L12 15L17 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"></path></svg>
                                    </div>
                                </div>
                              </div>
                               {isExpanded && itemState && (
                                <div className={styles.productContent}>
                                    <div className={styles.productExpandedDetails}>
                                        <div style={{ display: 'flex', gap: '32px' }}>
                                            <div className={styles.detailRow}><span className={styles.detailLabel}>Date Created</span><span className={styles.detailValue}>{formatShortDate(activeTicket.createdAt)}</span></div>
                                            <div className={styles.detailRow}><span className={styles.detailLabel}>Purchase Date</span><span className={styles.detailValue}>{formatShortDate(item.purchaseDate)}</span></div>
                                            <div className={styles.detailRowWithButtons}>
                                                <div className={styles.detailColumn}>
                                                    <span className={styles.detailLabel}>Purchase Location</span>
                                                    <span className={styles.detailValue}>{item.purchaseLocation}</span>
                                                </div>
                                                <div className={styles.buttonContainer}>
                                                    <button 
                                                        className={styles.editButton}
                                                        onClick={() => handleEditItem(activeTicket?.ticketID?.toString() || '', item)}
                                                        disabled={activeTicket.status === 1}
                                                        title={activeTicket.status === 1 ? 'Cannot edit items for closed ticket' : 'Edit item'}
                                                    >
                                                        ✏️
                                                    </button>
                                                    <button 
                                                        className={styles.deleteButton}
                                                        onClick={() => handleDeleteItem(activeTicket?.ticketID?.toString() || '', item?.id?.toString() || '', item)}
                                                        disabled={activeTicket.status === 1}
                                                        title={activeTicket.status === 1 ? 'Cannot delete items for closed ticket' : 'Delete item'}
                                                    >
                                                        🗑️
                                                    </button>
                                                    <button 
                                                        className={styles.activitiesButton}
                                                        onClick={() => {
                                                            setSelectedItemForActivities(item.id.toString());
                                                            setIsActivityLogsModalOpen(true);
                                                        }}
                                                        title="View item activities"
                                                    >
                                                        📋
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                        <div className={styles.detailRow}><span className={styles.detailLabel}>product Size</span><span className={styles.detailValue}>{item.productSize}</span></div>
                                        <div className={styles.requestSection}>
                                            <div className={styles.detailRow}><span className={styles.detailLabel}>Request Reason</span></div>
                                            <div className={styles.requestReason}>{item.requestReasonDetail}</div>
                                        </div>
                                        <div className={styles.actionSection}>
                                            <div className={styles.dateInspection}>
                                                <input 
                                                  type="checkbox" 
                                                  className={styles.inspectionCheckbox} 
                                                  checked={itemState.inspectionChecked ?? false} 
                                                  onChange={e => updateTicketItemState(key, { inspectionChecked: e.target.checked })}
                                                  disabled={activeTicket.status === 1}
                                                  title={activeTicket.status === 1 ? 'Cannot modify inspection for closed ticket' : 'Toggle inspection'}
                                                />
                                                <span className={styles.inspectionLabel}>المعاينة</span>
                                                <input
                                                  type="date"
                                                  className={styles.dateInput}
                                                  value={formatDateForInput(itemState.inspectionDate)}
                                                  onChange={e => updateTicketItemState(key, { inspectionDate: e.target.value ? new Date(e.target.value).toISOString() : undefined })}
                                                  disabled={!itemState.inspectionChecked || activeTicket.status === 1}
                                                  title={activeTicket.status === 1 ? 'Cannot modify inspection date for closed ticket' : 'Select inspection date'}
                                                />
                                            </div>
                                            <div className={styles.inspectionResult}>
                                                <span className={styles.resultLabel}>نتيجة المعاينة :</span>
                                                <div className={styles.resultInputWrapper}>
                                                  <textarea 
                                                    className={styles.resultTextarea} 
                                                    value={itemState.inspectionResult || ''} 
                                                    onChange={e => updateTicketItemState(key, { inspectionResult: e.target.value })}
                                                    disabled={!itemState.inspectionChecked || activeTicket.status === 1}
                                                    placeholder={activeTicket.status === 1 ? 'Ticket is closed' : (!itemState.inspectionChecked ? 'Check to enable' : 'Enter inspection result')}
                                                    title={activeTicket.status === 1 ? 'Cannot modify inspection result for closed ticket' : 'Enter inspection result'}
                                                  />
                                                </div>
                                            </div>
                                            <div className={styles.actionTypeSection}>
                                              <div className={styles.actionTypeHeader}>
                                                <h4>Action Type</h4>
                                                {isItemDirty[key] && (
                                                  <button
                                                    onClick={() => handleSaveItemChanges(key)}
                                                    className={`${styles.saveButton} ${styles.saveButtonGreen} ${styles.saveButtonSmall}`}
                                                    disabled={isActionFormInvalid[key] || activeTicket.status === 1}
                                                    title={activeTicket.status === 1 ? 'Cannot save changes to closed ticket' : 'Save changes'}
                                                  >
                                                    حفظ
                                                  </button>
                                                )}
                                              </div>
                                              <div className={styles.actionTypeSelector}>
                                                <button 
                                                  className={`${styles.actionTypeButton} ${itemState.selectedActionType === 'maintenance' ? styles.actionTypeSelected : ''}`}
                                                  onClick={() => handleActionTypeChange(key, 'maintenance')}
                                                  disabled={activeTicket.status === 1}
                                                  title={activeTicket.status === 1 ? 'Cannot modify items in closed ticket' : 'Select maintenance action'}
                                                >
                                                  {itemState.selectedActionType === 'maintenance' && <span className={styles.checkIcon}>✓</span>}
                                                  صيانة
                                                </button>
                                                <button 
                                                  className={`${styles.actionTypeButton} ${itemState.selectedActionType === 'change-same' ? styles.actionTypeSelected : ''}`}
                                                  onClick={() => handleActionTypeChange(key, 'change-same')}
                                                  disabled={activeTicket.status === 1}
                                                  title={activeTicket.status === 1 ? 'Cannot modify items in closed ticket' : 'Change to same product'}
                                                >
                                                  {itemState.selectedActionType === 'change-same' && <span className={styles.checkIcon}>✓</span>}
                                                  استبدال لنفس النوع
                                                </button>
                                                <button 
                                                  className={`${styles.actionTypeButton} ${itemState.selectedActionType === 'change-another' ? styles.actionTypeSelected : ''}`}
                                                  onClick={() => handleActionTypeChange(key, 'change-another')}
                                                  disabled={activeTicket.status === 1}
                                                  title={activeTicket.status === 1 ? 'Cannot modify items in closed ticket' : 'Change to another product'}
                                                >
                                                  {itemState.selectedActionType === 'change-another' && <span className={styles.checkIcon}>✓</span>}
                                                  استبدال لنوع اخر
                                                </button>
                                              </div>
                                              {itemState.selectedActionType && (
                                                <ActionForm 
                                                  actionType={itemState.selectedActionType}
                                                  formData={itemState.actionFormData || {}}
                                                  products={products}
                                                  companies={companies}
                                                  onFormChange={(field, value) => handleActionFormChange(key, field, value)}
                                                  onValidationChange={handleValidationChange}
                                                  itemKey={key}
                                                  disabled={activeTicket.status === 1}
                                                />
                                              )}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                               )}
                            </div>
                          )
                        })}
                     </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

type ActionFormProps = {
  actionType: ActionType;
  formData: Record<string, unknown>;
  products: Product[];
  companies: Company[];
  onFormChange: (field: string, value: unknown) => void;
  onValidationChange: (key: string, isInvalid: boolean) => void;
  itemKey: string;
  disabled?: boolean;
};

const ActionForm = ({ 
  actionType, 
  formData, 
  products, 
  companies,
  onFormChange, 
  onValidationChange,
  itemKey,
  disabled = false
}: ActionFormProps): JSX.Element => {
  const isMaintenance = actionType === 'maintenance';
  const isChange = actionType === 'change-same' || actionType === 'change-another';

  const handleBrandChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onFormChange('brandId', e.target.value as string);
  };
  
  const isFormInvalid = actionType === 'change-another' && (!formData.brandId || !formData.productId);

  useEffect(() => {
    onValidationChange(itemKey, isFormInvalid);
  }, [isFormInvalid, onValidationChange, itemKey]);

  return (
    <div className={styles.actionForm}>
      {isMaintenance && (
        <div className={styles.formField}>
          <label htmlFor="maintenanceSteps">خطوات الصيانة</label>
          <textarea 
            id="maintenanceSteps" 
            value={String(formData.maintenanceSteps || '')} 
            onChange={e => onFormChange('maintenanceSteps', e.target.value)} 
            disabled={disabled}
          />
        </div>
      )}
      {actionType === 'change-another' && (
        <>
          <div className={styles.formRow}>
            <div className={styles.formField}>
              <label htmlFor="brand">الشركة المصنعة (Brand)</label>
              <select id="brand" value={String(formData.brandId || '')} onChange={handleBrandChange} disabled={disabled}>
                <option value="">اختر الشركة</option>
                {companies.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
            </div>
            <div className={styles.formField}>
                <label htmlFor="newProduct">المنتج الجديد</label>
                <select 
                  id="newProduct" 
                  value={String(formData.productId || '')} 
                  onChange={e => onFormChange('productId', e.target.value)}
                  disabled={!formData.brandId || disabled}
                >
                  <option value="">اختر المنتج الجديد</option>
                  {products
                    .filter(p => p.company_id?.toString() === String(formData.brandId))
                    .map(p => (
                      <option key={p.id} value={p.id}>{p.product_name}</option>
                  ))}
                </select>
            </div>
          </div>
          <div className={styles.formField}>
            <label htmlFor="productSize">حجم المنتج</label>
            <input id="productSize" type="text" value={String(formData.productSize || '')} onChange={e => onFormChange('productSize', e.target.value)} disabled={disabled} />
          </div>
        </>
      )}
      {actionType === 'change-same' && (
         <div className={styles.formField}>
            <label htmlFor="productSize">حجم المنتج</label>
            <input id="productSize" type="text" value={String(formData.productSize || '')} onChange={e => onFormChange('productSize', e.target.value)} disabled={disabled} />
        </div>
      )}
      
      <div className={styles.formRow}>
          {isMaintenance && (
            <div className={styles.formField}>
              <label htmlFor="maintenanceCost">تكلفة الصيانة</label>
              <input id="maintenanceCost" type="number" value={String(formData.maintenanceCost || '')} onChange={e => onFormChange('maintenanceCost', e.target.value)} disabled={disabled} />
            </div>
          )}

          {isChange && (
              <div className={styles.formField}>
                  <label htmlFor="cost">التكلفة</label>
                  <input id="cost" type="number" value={String(formData.cost || '')} onChange={e => onFormChange('cost', e.target.value)} disabled={disabled} />
              </div>
          )}
          <div className={styles.formField}>
              <label htmlFor="clientApproval">موافقة العميل</label>
              <select id="clientApproval" value={String(formData.clientApproval || '')} onChange={e => onFormChange('clientApproval', e.target.value)} disabled={disabled}>
                <option value="">اختر موافقة العميل</option>
                <option value="approved">موافق</option>
                <option value="rejected">مرفوض</option>
              </select>
          </div>
      </div>
      
      {formData.clientApproval === 'rejected' && (
         <div className={styles.formField}>
            <label htmlFor="refusalReason">سبب الرفض</label>
            <textarea id="refusalReason" value={String(formData.refusalReason || '')} onChange={e => onFormChange('refusalReason', e.target.value)} disabled={disabled} />
        </div>
      )}
      
      <div className={styles.formColumn}>
        <div className={styles.checkboxGroup}>
          <label><input type="checkbox" checked={Boolean(formData.pulled)} onChange={e => onFormChange('pulled', e.target.checked)} disabled={disabled} /> تم السحب</label>
          {formData.pulled && <input type="date" value={String(formData.pullDate || '')} onChange={e => onFormChange('pullDate', e.target.value)} disabled={disabled} />}
        </div>
        <div className={styles.checkboxGroup}>
          <label><input type="checkbox" checked={Boolean(formData.delivered)} onChange={e => onFormChange('delivered', e.target.checked)} disabled={disabled} /> تم التسليم</label>
          {formData.delivered && <input type="date" value={String(formData.deliveryDate || '')} onChange={e => onFormChange('deliveryDate', e.target.value)} disabled={disabled} />}
        </div>
      </div>
    </div>
  );
};
