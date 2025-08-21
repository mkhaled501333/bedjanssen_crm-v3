import React, { useState } from 'react';
import styles from './CloseTicketModal.module.css';

interface CloseTicketModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (notes: string) => void;
  ticketId: string;
  isLoading?: boolean;
}

export function CloseTicketModal({ 
  isOpen, 
  onClose, 
  onConfirm, 
  ticketId, 
  isLoading = false 
}: CloseTicketModalProps) {
  const [notes, setNotes] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!notes.trim()) {
      setError('Please enter closing notes');
      return;
    }
    
    setError('');
    onConfirm(notes.trim());
  };

  const handleClose = () => {
    if (!isLoading) {
      setNotes('');
      setError('');
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className={styles.modalOverlay} onClick={handleClose}>
      <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
        <div className={styles.modalHeader}>
          <h2>Close Ticket #{ticketId}</h2>
          <button 
            className={styles.closeButton} 
            onClick={handleClose}
            disabled={isLoading}
          >
            ×
          </button>
        </div>
        
        <form onSubmit={handleSubmit}>
          <div className={styles.modalBody}>
            <p className={styles.confirmationText}>
              Are you sure you want to close this ticket? This action cannot be undone.
            </p>
            
            <div className={styles.notesSection}>
              <label htmlFor="closingNotes" className={styles.notesLabel}>
                Closing Notes *
              </label>
              <textarea
                id="closingNotes"
                className={styles.notesTextarea}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Please provide details about the ticket resolution..."
                rows={4}
                disabled={isLoading}
                required
              />
              {error && <div className={styles.errorMessage}>{error}</div>}
            </div>
          </div>
          
          <div className={styles.modalFooter}>
            <button 
              type="button" 
              className={styles.cancelButton}
              onClick={handleClose}
              disabled={isLoading}
            >
              Cancel
            </button>
            <button 
              type="submit" 
              className={styles.confirmButton}
              disabled={isLoading || !notes.trim()}
            >
              {isLoading ? 'Closing...' : 'Close Ticket'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}