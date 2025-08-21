
import { useState, useEffect } from 'react';
import Select from 'react-select';
import type { CustomerDetails, CustomerPhone, Governorate, City } from '../../../types';
import styles from './EditCustomerModal.module.css';
import { getGovernoratesWithCities, addCustomerPhone, updateCustomerPhone, deleteCustomerPhone } from '../../../api';

interface EditCustomerModalProps {
  customer: CustomerDetails;
  onClose: () => void;
  onSave: (updatedCustomer: CustomerDetails) => void;
  onDataChange: () => void;
}

export function EditCustomerModal({ customer, onClose, onSave, onDataChange }: EditCustomerModalProps) {
  const [formData, setFormData] = useState<CustomerDetails>(customer);
  const [governorates, setGovernorates] = useState<Governorate[]>([]);
  const [selectedGovernorate, setSelectedGovernorate] = useState<{ label: string, value: number } | null>(null);
  const [cities, setCities] = useState<City[]>([]);
  const [selectedCity, setSelectedCity] = useState<{ label: string, value: number } | null>(null);
  const [newPhone, setNewPhone] = useState('');
  const [editingPhoneId, setEditingPhoneId] = useState<number | null>(null);
  const [editingPhoneNumber, setEditingPhoneNumber] = useState('');

  useEffect(() => {
    setFormData(customer);
    const fetchGovernorates = async () => {
      try {
        const data = await getGovernoratesWithCities();
        setGovernorates(data);
        const currentGov = data.find(g => g.name === customer.governorate);
        if (currentGov) {
          setSelectedGovernorate({ label: currentGov.name, value: currentGov.id });
          setCities(currentGov.cities);
          const currentCity = currentGov.cities.find(c => c.name === customer.city);
          if (currentCity) {
            setSelectedCity({ label: currentCity.name, value: currentCity.id });
            setFormData(prev => ({ ...prev, cityId: currentCity.id, governorateId: currentGov.id }));
          }
        }
      } catch (error) {
        console.error("Failed to fetch governorates", error);
      }
    };
    fetchGovernorates();
  }, [customer]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev: CustomerDetails) => ({ ...prev, [name]: value } as CustomerDetails));
  };

  const handleGovernorateChange = (selectedOption: unknown) => {
    setSelectedGovernorate(selectedOption as { label: string, value: number } | null);
    const selectedGov = governorates.find(g => g.id === (selectedOption as { value: number }).value);
    setCities(selectedGov ? selectedGov.cities : []);
    setSelectedCity(null);
    setFormData(prev => ({ ...prev, governorateId: (selectedOption as { value: number }).value, cityId: undefined }));
  };

  const handleCityChange = (selectedOption: unknown) => {
    setSelectedCity(selectedOption as { label: string, value: number } | null);
    setFormData(prev => ({ ...prev, cityId: (selectedOption as { value: number }).value }));
  };

  const handleAddPhone = async () => {
    if (!newPhone.trim()) return;
    try {
      await addCustomerPhone(customer.id.toString(), {
        phone: newPhone,
        phone_type: 1,
        company_id: customer.companyId,
        created_by: 1,
      });
      setNewPhone('');
      onDataChange();
    } catch (error) {
      console.error("Failed to add phone", error);
    }
  };

  const handleEditPhone = (phone: CustomerPhone) => {
    setEditingPhoneId(phone.id);
    setEditingPhoneNumber(phone.phone);
  };

  const handleUpdatePhone = async (phoneId: number) => {
    if (!editingPhoneNumber.trim()) return;
    try {
      await updateCustomerPhone(customer.id.toString(), phoneId, editingPhoneNumber);
      setEditingPhoneId(null);
      setEditingPhoneNumber('');
      onDataChange();
    } catch (error) {
      console.error("Failed to update phone", error);
    }
  };

  const handleDeletePhone = async (phoneId: number) => {
    try {
      await deleteCustomerPhone(customer.id.toString(), phoneId);
      onDataChange();
    } catch (error) {
      console.error("Failed to delete phone", error);
    }
  };

  const handleSave = () => {
    onSave(formData);
  };

  const isCityRequired = !!(formData.governorateId && !formData.cityId);

  return (
    <div className={styles['modal-overlay']}>
      <div className={styles['modal-content']}>
        <div className={styles['modal-header']}>
          <h2 className={styles['modal-title']}>Edit Customer Information</h2>
          <button onClick={onClose} className={styles['close-button']}>&times;</button>
        </div>
        <div className={styles['modal-body']}>
          <div className={styles['form-group']}>
            <label htmlFor="name">Name</label>
            <input type="text" id="name" name="name" value={formData.name} onChange={handleChange} />
          </div>
          <div className={styles['form-row']}>
            <div className={styles['form-group']}>
              <label htmlFor="governorate">Governorate</label>
              <Select
                id="governorate"
                name="governorateId"
                value={selectedGovernorate}
                onChange={handleGovernorateChange}
                options={governorates.map(gov => ({ value: gov.id, label: gov.name }))}
                isSearchable
              />
            </div>
            <div className={styles['form-group']}>
              <label htmlFor="city">City</label>
              <Select
                id="city"
                name="cityId"
                value={selectedCity}
                onChange={handleCityChange}
                options={cities.map(city => ({ value: city.id, label: city.name }))}
                isSearchable
                isDisabled={!selectedGovernorate}
              />
              {isCityRequired && <p className={styles['error-message']}>Please select a city.</p>}
            </div>
          </div>
          <div className={styles['form-group']}>
            <label htmlFor="address">Address</label>
            <input type="text" id="address" name="address" value={formData.address || ''} onChange={handleChange} />
          </div>
          <div className={styles['form-group']}>
            <label htmlFor="notes">Notes</label>
            <input type="text" id="notes" name="notes" value={formData.notes || ''} onChange={handleChange} />
          </div>
          <div className={styles['form-group']}>
            <label>Phones</label>
            <div className={styles['phone-inputs']}>
              {formData.phones.map((phone: CustomerPhone) => (
                <div key={phone.id} className={styles['phone-item']}>
                  {editingPhoneId === phone.id ? (
                    <>
                      <input
                        type="text"
                        value={editingPhoneNumber}
                        onChange={(e) => setEditingPhoneNumber(e.target.value)}
                      />
                      <button onClick={() => handleUpdatePhone(phone.id)}>Save</button>
                      <button onClick={() => setEditingPhoneId(null)}>Cancel</button>
                    </>
                  ) : (
                    <>
                      <input
                        type="text"
                        value={phone.phone}
                        readOnly
                      />
                      <button onClick={() => handleEditPhone(phone)}>Edit</button>
                      <button onClick={() => handleDeletePhone(phone.id)}>Delete</button>
                    </>
                  )}
                </div>
              ))}
            </div>
            <div className={styles['add-phone']}>
              <input 
                type="text" 
                value={newPhone} 
                onChange={(e) => setNewPhone(e.target.value)} 
                placeholder="New phone number"
              />
              <button onClick={handleAddPhone}>Add Phone</button>
            </div>
          </div>
        </div>
        <div className={styles['modal-footer']}>
          <button onClick={onClose} className={`${styles.button} ${styles['cancel-button']}`}>Cancel</button>
          <button onClick={handleSave} className={`${styles.button} ${styles['save-button']}`} disabled={isCityRequired}>Save Changes</button>
        </div>
      </div>
    </div>
  );
}