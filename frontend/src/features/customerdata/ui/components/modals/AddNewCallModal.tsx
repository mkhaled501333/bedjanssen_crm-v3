
import { useState, useEffect } from 'react';
import Select from 'react-select';
import styles from './AddNewCallModal.module.css';
import { getCallCategories } from '../../../api';

export type AddNewCallModalProps = {
  onClose: () => void;
  onSave: (callData: Record<string, unknown>) => void;
};
type CallCategory = {
  id: number;
  name: string;
};
export function AddNewCallModal({ onClose, onSave }: AddNewCallModalProps) {
  const [callType, setCallType] = useState('incoming');
  const [categories, setCategories] = useState<CallCategory[]>([]);
  const [description, setDescription] = useState('');
  const [descriptionError, setDescriptionError] = useState('');
  const [minutes, setMinutes] = useState('00');
  const [seconds, setSeconds] = useState('00');
  const [selectedCategory, setSelectedCategory] = useState<{ value: number; label: string } | null>(null);

  useEffect(() => {
    async function fetchCategories() {
      try {
        const fetchedCategories = await getCallCategories();
        setCategories(fetchedCategories);
        if (fetchedCategories.length > 0) {
          setSelectedCategory({ value: fetchedCategories[0].id, label: fetchedCategories[0].name });
        }
      } catch (error) {
        console.error('Failed to fetch call categories', error);
      }
    }
    fetchCategories();
  }, []);

  const handleTimeChange = (
    e: React.ChangeEvent<HTMLInputElement>,
    setter: React.Dispatch<React.SetStateAction<string>>,
    max: number
  ) => {
    const value = e.target.value.slice(0, 2); // Limit to 2 chars
    if (/^\d*$/.test(value)) {
      if (Number(value) <= max) {
        setter(value);
      }
    }
  };

  const formatTimeValue = (value: string) => value.padStart(2, '0');

  const handleTimeBlur = (
    e: React.FocusEvent<HTMLInputElement>,
    setter: React.Dispatch<React.SetStateAction<string>>
  ) => {
    setter(formatTimeValue(e.target.value));
  };

  const validateDescription = () => {
    if (!description.trim()) {
      setDescriptionError('وصف المكالمة مطلوب');
      return false;
    }
    if (!selectedCategory) {
      // You might want to set an error for the category as well
      return false;
    }
    setDescriptionError('');
    return true;
  };

  const handleSave = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (!validateDescription()) {
      return;
    }

    const callData = {
      type: callType,
      category: selectedCategory!.value,
      description: description,
      notes: (event.currentTarget.elements.namedItem('notes') as HTMLTextAreaElement).value,
      minutes: minutes,
      seconds: seconds,
    };
    onSave(callData);
  };

  return (
    <div className={styles.modalOverlay}>
      <div className={styles.modalContent}>
        <div className={styles.modalHeader}>
          <h2 className={styles.modalTitle}>
            <span>📞</span>
            إضافة سجل مكالمة جديد
          </h2>
          <button onClick={onClose} className={styles.closeButton}>
            &times;
          </button>
        </div>
        <form onSubmit={handleSave} noValidate>
          <div className={styles.form}>
            <div className={styles.formGroup}>
              <div className={styles.labelWithControl}>
                <label>نوع المكالمة:</label>
                <div className={styles.segmentedControl}>
                  <button
                    type="button"
                    className={callType === 'incoming' ? styles.active : ''}
                    onClick={() => setCallType('incoming')}
                  >
                    واردة
                  </button>
                  <button
                    type="button"
                    className={callType === 'outgoing' ? styles.active : ''}
                    onClick={() => setCallType('outgoing')}
                  >
                    صادرة
                  </button>
                </div>
              </div>
            </div>
            <div className={styles.formGroup}>
              <label htmlFor="category">فئة المكالمة</label>
              <Select
                id="category"
                name="category"
                options={categories.map(cat => ({ value: cat.id, label: cat.name }))}
                value={selectedCategory}
                onChange={setSelectedCategory}
                placeholder="ابحث عن فئة..."
                isSearchable
              />
            </div>
            <div className={styles.formGroup}>
              <label htmlFor="description">وصف المكالمة</label>
              <textarea
                id="description"
                name="description"
                className={`${styles.textarea} ${descriptionError ? styles.inputError : ''}`}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                onBlur={validateDescription}
              ></textarea>
              {descriptionError && <span className={styles.errorMessage}>{descriptionError}</span>}
            </div>
            <div className={styles.formGroup}>
              <label>مدة المكالمة</label>
              <div className={styles.durationContainer}>
                <div className={styles.durationInputGroup}>
                  <label htmlFor="minutes">دقائق</label>
                  <input
                    id="minutes"
                    name="minutes"
                    type="text"
                    className={`${styles.input} ${styles.durationInput}`}
                    value={minutes}
                    onChange={(e) => handleTimeChange(e, setMinutes, 99)}
                    onBlur={(e) => handleTimeBlur(e, setMinutes)}
                  />
                </div>
                <span>:</span>
                <div className={styles.durationInputGroup}>
                  <label htmlFor="seconds">ثواني</label>
                  <input
                    id="seconds"
                    name="seconds"
                    type="text"
                    className={`${styles.input} ${styles.durationInput}`}
                    value={seconds}
                    onChange={(e) => handleTimeChange(e, setSeconds, 59)}
                    onBlur={(e) => handleTimeBlur(e, setSeconds)}
                  />
                </div>
              </div>
            </div>
            <div className={styles.formGroup}>
              <label htmlFor="notes">ملاحظات المكالمة</label>
              <textarea id="notes" name="notes" className={styles.textarea}></textarea>
            </div>
          </div>
          <div className={styles.modalFooter}>
            <button type="submit" className={`${styles.button} ${styles.saveButton}`}>
              حفظ
            </button>
            <button type="button" onClick={onClose} className={`${styles.button} ${styles.cancelButton}`}>
              إلغاء
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}