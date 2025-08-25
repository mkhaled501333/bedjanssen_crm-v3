// Excel Table Functionality

// Global variables for filter functionality
let activeFilters = {};
let filteredData = null;
let originalData = null;
let selectedRows = new Set();

// Make cells editable on double-click
document.addEventListener('DOMContentLoaded', function() {
    // Populate table with maintenance data
    if (typeof populateTableWithMaintenanceData === 'function') {
        populateTableWithMaintenanceData();
    }
    
    // Store original data for filtering
    storeOriginalData();
    
    // Make cells editable on double-click
    document.querySelectorAll('.cell-input').forEach(input => {
        input.addEventListener('dblclick', function() {
            if (!this.readOnly) {
                this.focus();
                this.select();
            }
        });
    });

    // Add column headers dynamically
    document.querySelectorAll('th:not(:first-child)').forEach((header, index) => {
        // Headers are now set in HTML, just ensure filter icons work
        const filterIcon = header.querySelector('.filter-icon');
        if (filterIcon) {
            // Extract column name from header text for filter functionality
            const columnName = header.textContent.trim().replace(/\s+/g, '');
            filterIcon.onclick = function() { toggleFilter(this, columnName); };
        }
    });

    // Toolbar button functionality
    document.querySelectorAll('.toolbar-button').forEach(button => {
        button.addEventListener('click', function() {
            alert(`Clicked: ${this.textContent}`);
        });
    });

    // Sheet tab functionality
    document.querySelectorAll('.sheet-tab').forEach(tab => {
        tab.addEventListener('click', function() {
            document.querySelectorAll('.sheet-tab').forEach(t => t.classList.remove('active'));
            this.classList.add('active');
        });
    });

    // Add keyboard navigation
    addKeyboardNavigation();
    
    // Add cell selection functionality
    addCellSelection();
    
    // Close filter dropdowns when clicking outside
    document.addEventListener('click', function(e) {
        if (!e.target.closest('.filter-dropdown') && !e.target.classList.contains('filter-icon')) {
            closeAllFilters();
        }
    });
});

// Toggle select all checkbox
function toggleSelectAll(selectAllCheckbox) {
    const rowCheckboxes = document.querySelectorAll('.row-checkbox');
    rowCheckboxes.forEach(checkbox => {
        checkbox.checked = selectAllCheckbox.checked;
        if (selectAllCheckbox.checked) {
            selectedRows.add(checkbox.value);
        } else {
            selectedRows.delete(checkbox.value);
        }
    });
    updateSelectionCount();
}

// Toggle individual row selection
function toggleRowSelection(checkbox) {
    if (checkbox.checked) {
        selectedRows.add(checkbox.value);
    } else {
        selectedRows.delete(checkbox.value);
    }
    
    // Update select all checkbox state
    const selectAllCheckbox = document.getElementById('selectAll');
    const rowCheckboxes = document.querySelectorAll('.row-checkbox');
    const allChecked = Array.from(rowCheckboxes).every(cb => cb.checked);
    const someChecked = Array.from(rowCheckboxes).some(cb => cb.checked);
    
    selectAllCheckbox.checked = allChecked;
    selectAllCheckbox.indeterminate = someChecked && !allChecked;
    
    updateSelectionCount();
}

// Update selection count display
function updateSelectionCount() {
    const footer = document.querySelector('.excel-footer div:last-child');
    if (footer) {
        const totalRecords = document.querySelectorAll('.row-checkbox').length;
        const selectedCount = selectedRows.size;
        if (selectedCount > 0) {
            footer.textContent = `Ready | ${selectedCount} of ${totalRecords} selected | Maintenance System`;
        } else {
            footer.textContent = `Ready | ${totalRecords} records | Maintenance System`;
        }
    }
}

// Store original table data for filtering
function storeOriginalData() {
    const table = document.querySelector('.excel-table');
    const rows = Array.from(table.querySelectorAll('tbody tr'));
    
    originalData = rows.map(row => {
        const cells = Array.from(row.querySelectorAll('td'));
        return cells.map(cell => {
            if (cell.querySelector('.cell-input')) {
                return cell.querySelector('.cell-input').value || '';
            } else {
                return cell.textContent || '';
            }
        });
    });
}

// Toggle filter dropdown for a specific column
function toggleFilter(filterIcon, column) {
    closeAllFilters();
    
    const headerCell = filterIcon.closest('th');
    const columnIndex = getColumnIndex(column);
    
    // Create filter dropdown
    const dropdown = createFilterDropdown(column, columnIndex);
    
    // Position dropdown
    headerCell.appendChild(dropdown);
    
    // Show dropdown
    setTimeout(() => {
        dropdown.classList.add('show');
    }, 10);
    
    // Update filter icon
    filterIcon.textContent = '🔽';
    filterIcon.classList.add('active');
}

// Create filter dropdown for a column
function createFilterDropdown(column, columnIndex) {
    const dropdown = document.createElement('div');
    dropdown.className = 'filter-dropdown';
    
    // Get unique values for this column
    const uniqueValues = getUniqueColumnValues(columnIndex);
    
    // Create filter header
    const header = document.createElement('div');
    header.className = 'filter-header';
    header.textContent = `Filter ${column}`;
    dropdown.appendChild(header);
    
    // Create search input
    const searchInput = document.createElement('input');
    searchInput.type = 'text';
    searchInput.className = 'filter-search';
    searchInput.placeholder = 'Search...';
    searchInput.addEventListener('input', function() {
        filterOptions(this.value, optionsContainer);
    });
    dropdown.appendChild(searchInput);
    
    // Create options container
    const optionsContainer = document.createElement('div');
    optionsContainer.className = 'filter-options';
    
    // Add "Select All" option
    const selectAllOption = createFilterOption('Select All', true, true);
    selectAllOption.addEventListener('change', function() {
        const checkboxes = optionsContainer.querySelectorAll('input[type="checkbox"]:not([data-select-all])');
        checkboxes.forEach(cb => {
            cb.checked = this.checked;
        });
    });
    optionsContainer.appendChild(selectAllOption);
    
    // Add individual options
    uniqueValues.forEach(value => {
        if (value && value.trim() !== '') {
            const option = createFilterOption(value, false, false);
            optionsContainer.appendChild(option);
        }
    });
    
    dropdown.appendChild(optionsContainer);
    
    // Create action buttons
    const actions = document.createElement('div');
    actions.className = 'filter-actions';
    
    const applyBtn = document.createElement('button');
    applyBtn.textContent = 'Apply';
    applyBtn.className = 'apply';
    applyBtn.addEventListener('click', function() {
        applyFilter(column, columnIndex, optionsContainer);
        closeAllFilters();
    });
    
    const clearBtn = document.createElement('button');
    clearBtn.textContent = 'Clear';
    clearBtn.className = 'clear';
    clearBtn.addEventListener('click', function() {
        clearFilter(column, columnIndex);
        closeAllFilters();
    });
    
    actions.appendChild(clearBtn);
    actions.appendChild(applyBtn);
    dropdown.appendChild(actions);
    
    return dropdown;
}

// Create a filter option
function createFilterOption(value, isSelectAll, checked) {
    const option = document.createElement('div');
    option.className = 'filter-option';
    
    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.checked = checked;
    if (isSelectAll) {
        checkbox.setAttribute('data-select-all', 'true');
    }
    
    const label = document.createElement('label');
    label.textContent = value;
    
    option.appendChild(checkbox);
    option.appendChild(label);
    
    return option;
}

// Filter options based on search input
function filterOptions(searchTerm, optionsContainer) {
    const options = optionsContainer.querySelectorAll('.filter-option:not([data-select-all])');
    options.forEach(option => {
        const label = option.querySelector('label');
        const text = label.textContent.toLowerCase();
        if (text.includes(searchTerm.toLowerCase())) {
            option.style.display = 'flex';
        } else {
            option.style.display = 'none';
        }
    });
}

// Get unique values for a column
function getUniqueColumnValues(columnIndex) {
    const values = new Set();
    originalData.forEach(row => {
        if (row[columnIndex]) {
            values.add(row[columnIndex]);
        }
    });
    return Array.from(values).sort();
}

// Get column index from column name
function getColumnIndex(columnName) {
    const headers = document.querySelectorAll('th:not(.corner-cell)');
    for (let i = 0; i < headers.length; i++) {
        const headerText = headers[i].textContent.trim().replace(/\s+/g, '');
        if (headerText === columnName) {
            return i;
        }
    }
    return 0; // Default to first column if not found
}

// Apply filter to a column
function applyFilter(column, columnIndex, optionsContainer) {
    const selectedValues = [];
    const checkboxes = optionsContainer.querySelectorAll('input[type="checkbox"]:not([data-select-all])');
    
    checkboxes.forEach(checkbox => {
        if (checkbox.checked) {
            const label = checkbox.nextElementSibling.textContent;
            selectedValues.push(label);
        }
    });
    
    if (selectedValues.length > 0) {
        activeFilters[column] = selectedValues;
        filterTableData();
        updateFilterIcon(column, selectedValues.length);
    }
}

// Clear filter for a column
function clearFilter(column, columnIndex) {
    delete activeFilters[column];
    filterTableData();
    updateFilterIcon(column, 0);
}

// Filter table data based on active filters
function filterTableData() {
    if (Object.keys(activeFilters).length === 0) {
        // No filters, show all data
        showAllData();
        return;
    }
    
    const filteredRows = originalData.filter(row => {
        return Object.entries(activeFilters).every(([column, allowedValues]) => {
            const columnIndex = getColumnIndex(column);
            const cellValue = row[columnIndex];
            return allowedValues.includes(cellValue);
        });
    });
    
    displayFilteredData(filteredRows);
}

// Display filtered data
function displayFilteredData(filteredRows) {
    const tbody = document.querySelector('.excel-table tbody');
    const existingRows = tbody.querySelectorAll('tr:not(:first-child)');
    
    // Remove existing data rows (keep header row)
    existingRows.forEach(row => row.remove());
    
    // Add filtered rows
    filteredRows.forEach((rowData, index) => {
        const newRow = document.createElement('tr');
        
        // Add row number
        const rowNumberCell = document.createElement('td');
        rowNumberCell.className = 'row-number';
        rowNumberCell.textContent = index + 1;
        newRow.appendChild(rowNumberCell);
        
        // Add data cells
        rowData.forEach((cellValue, cellIndex) => {
            const cell = document.createElement('td');
            const input = document.createElement('input');
            input.type = 'text';
            input.className = 'cell-input';
            input.value = cellValue;
            
            // Apply special styling for certain columns
            if (cellIndex === 6) { // Status column
                cell.className = 'status-cell';
                cell.textContent = cellValue;
            } else if (cellIndex === 7) { // Priority column
                if (cellValue === 'High') {
                    cell.className = 'priority-high';
                } else if (cellValue === 'Medium') {
                    cell.className = 'priority-medium';
                } else if (cellValue === 'Low') {
                    cell.className = 'priority-low';
                }
                cell.textContent = cellValue;
            } else if (cellIndex === 8) { // Revenue column
                cell.className = 'currency';
                cell.textContent = cellValue;
            } else {
                cell.appendChild(input);
            }
            
            newRow.appendChild(cell);
        });
        
        tbody.appendChild(newRow);
    });
    
    // Update footer with filtered count
    updateFooterCount(filteredRows.length);
}

// Show all data (remove filters)
function showAllData() {
    const tbody = document.querySelector('.excel-table tbody');
    const existingRows = tbody.querySelectorAll('tr:not(:first-child)');
    
    // Remove existing data rows
    existingRows.forEach(row => row.remove());
    
    // Restore original data
    originalData.forEach((rowData, index) => {
        const newRow = document.createElement('tr');
        
        // Add row number
        const rowNumberCell = document.createElement('td');
        rowNumberCell.className = 'row-number';
        rowNumberCell.textContent = index + 1;
        newRow.appendChild(rowNumberCell);
        
        // Add data cells
        rowData.forEach((cellValue, cellIndex) => {
            const cell = document.createElement('td');
            const input = document.createElement('input');
            input.type = 'text';
            input.className = 'cell-input';
            input.value = cellValue;
            
            // Apply special styling for certain columns
            if (cellIndex === 6) { // Status column
                cell.className = 'status-cell';
                cell.textContent = cellValue;
            } else if (cellIndex === 7) { // Priority column
                if (cellValue === 'High') {
                    cell.className = 'priority-high';
                } else if (cellValue === 'Medium') {
                    cell.className = 'priority-medium';
                } else if (cellValue === 'Low') {
                    cell.className = 'priority-low';
                }
                cell.textContent = cellValue;
            } else if (cellIndex === 8) { // Revenue column
                cell.className = 'currency';
                cell.textContent = cellValue;
            } else {
                cell.appendChild(input);
            }
            
            newRow.appendChild(cell);
        });
        
        tbody.appendChild(newRow);
    });
    
    // Update footer with original count
    updateFooterCount(originalData.length);
}

// Update footer count
function updateFooterCount(count) {
    const footer = document.querySelector('.excel-footer');
    const countText = footer.querySelector('div:last-child');
    if (countText) {
        countText.textContent = `Ready | ${count} records | Total Revenue: $${calculateTotalRevenue(count)}`;
    }
}

// Calculate total revenue for filtered data
function calculateTotalRevenue(rowCount) {
    // This is a simplified calculation - in a real app you'd sum the actual revenue values
    const baseRevenue = 1562900; // Base revenue for 25 records
    const avgRevenue = baseRevenue / 25;
    return (avgRevenue * rowCount).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });
}

// Close all filter dropdowns
function closeAllFilters() {
    document.querySelectorAll('.filter-dropdown').forEach(dropdown => {
        dropdown.remove();
    });
    
    document.querySelectorAll('.filter-icon').forEach(icon => {
        icon.classList.remove('active');
    });
}

// Clear all active filters
function clearAllFilters() {
    activeFilters = {};
    showAllData();
    
    // Reset all filter icons
    document.querySelectorAll('.filter-icon').forEach(icon => {
        icon.classList.remove('active');
    });
    
    // Remove filtered styling from headers
    document.querySelectorAll('th').forEach(header => {
        header.classList.remove('column-filtered');
        const badge = header.querySelector('.filter-count');
        if (badge) {
            badge.remove();
        }
    });
}

// Update filter icon to show active state
function updateFilterIcon(column, filterCount) {
    const headerCells = document.querySelectorAll('th');
    const columnIndex = getColumnIndex(column);
    const headerCell = headerCells[columnIndex + 1]; // +1 for corner cell
    const filterIcon = headerCell.querySelector('.filter-icon');
    
    if (filterCount > 0) {
        filterIcon.textContent = '🔽';
        filterIcon.classList.add('active');
        headerCell.classList.add('column-filtered');
        
        // Add filter count badge
        let badge = headerCell.querySelector('.filter-count');
        if (!badge) {
            badge = document.createElement('span');
            badge.className = 'filter-count';
            headerCell.appendChild(badge);
        }
        badge.textContent = filterCount;
    } else {
        filterIcon.textContent = '🔽';
        filterIcon.classList.remove('active');
        headerCell.classList.remove('column-filtered');
        
        const badge = headerCell.querySelector('.filter-count');
        if (badge) {
            badge.remove();
        }
    }
}

// Keyboard navigation for Excel-like experience
function addKeyboardNavigation() {
    document.addEventListener('keydown', function(e) {
        const activeElement = document.activeElement;
        
        if (activeElement.classList.contains('cell-input')) {
            const currentCell = activeElement.closest('td');
            const currentRow = currentCell.closest('tr');
            const currentRowIndex = Array.from(currentRow.parentNode.children).indexOf(currentRow);
            const currentCellIndex = Array.from(currentRow.children).indexOf(currentCell);
            
            let nextCell = null;
            
            switch(e.key) {
                case 'ArrowUp':
                    if (currentRowIndex > 1) { // Skip header row
                        const prevRow = currentRow.parentNode.children[currentRowIndex - 1];
                        nextCell = prevRow.children[currentCellIndex];
                    }
                    break;
                case 'ArrowDown':
                    if (currentRowIndex < currentRow.parentNode.children.length - 1) {
                        const nextRow = currentRow.parentNode.children[currentRowIndex + 1];
                        nextCell = nextRow.children[currentCellIndex];
                    }
                    break;
                case 'ArrowLeft':
                    if (currentCellIndex > 0) {
                        nextCell = currentRow.children[currentCellIndex - 1];
                    }
                    break;
                case 'ArrowRight':
                    if (currentCellIndex < currentRow.children.length - 1) {
                        nextCell = currentRow.children[currentCellIndex + 1];
                    }
                    break;
                case 'Enter':
                    e.preventDefault();
                    if (e.shiftKey) {
                        // Shift+Enter: Move up
                        if (currentRowIndex > 1) {
                            const prevRow = currentRow.parentNode.children[currentRowIndex - 1];
                            nextCell = prevRow.children[currentCellIndex];
                        }
                    } else {
                        // Enter: Move down
                        if (currentRowIndex < currentRow.parentNode.children.length - 1) {
                            const nextRow = currentRow.parentNode.children[currentRowIndex + 1];
                            nextCell = nextRow.children[currentCellIndex];
                        }
                    }
                    break;
                case 'Tab':
                    e.preventDefault();
                    if (e.shiftKey) {
                        // Shift+Tab: Move left
                        if (currentCellIndex > 0) {
                            nextCell = currentRow.children[currentCellIndex - 1];
                        }
                    } else {
                        // Tab: Move right
                        if (currentCellIndex < currentRow.children.length - 1) {
                            nextCell = currentRow.children[currentCellIndex + 1];
                        }
                    }
                    break;
            }
            
            if (nextCell && nextCell.querySelector('.cell-input')) {
                const nextInput = nextCell.querySelector('.cell-input');
                if (!nextInput.readOnly) {
                    nextInput.focus();
                    nextInput.select();
                }
            }
        }
    });
}

// Cell selection functionality
function addCellSelection() {
    let selectedCell = null;
    
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('cell-input')) {
            // Remove previous selection
            if (selectedCell) {
                selectedCell.style.outline = 'none';
            }
            
            // Add selection outline
            selectedCell = e.target;
            selectedCell.style.outline = '2px solid #0078d4';
            selectedCell.style.outlineOffset = '-2px';
        }
    });
    
    // Remove selection when clicking outside
    document.addEventListener('click', function(e) {
        if (!e.target.classList.contains('cell-input')) {
            if (selectedCell) {
                selectedCell.style.outline = 'none';
                selectedCell = null;
            }
        }
    });
}

// Export table data to CSV
function exportToCSV() {
    const table = document.querySelector('.excel-table');
    const rows = Array.from(table.querySelectorAll('tr'));
    
    let csvContent = '';
    
    rows.forEach(row => {
        const cells = Array.from(row.querySelectorAll('td, th'));
        const rowData = cells.map(cell => {
            let cellText = '';
            if (cell.querySelector('.cell-input')) {
                cellText = cell.querySelector('.cell-input').value || '';
            } else {
                cellText = cell.textContent || '';
            }
            // Escape quotes and wrap in quotes if contains comma
            cellText = cellText.replace(/"/g, '""');
            if (cellText.includes(',') || cellText.includes('"') || cellText.includes('\n')) {
                cellText = `"${cellText}"`;
            }
            return cellText;
        });
        csvContent += rowData.join(',') + '\n';
    });
    
    // Create download link
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', 'excel-table-export.csv');
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

// Add new row functionality
function addNewRow() {
    const tbody = document.querySelector('.excel-table tbody');
    const newRow = document.createElement('tr');
    
    // Create selection checkbox cell
    const checkboxCell = document.createElement('td');
    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.className = 'row-checkbox';
    checkbox.value = 'new-' + Date.now(); // Unique ID for new row
    checkbox.addEventListener('change', function() {
        toggleRowSelection(this);
    });
    checkboxCell.appendChild(checkbox);
    newRow.appendChild(checkboxCell);
    
    // Create data cells (19 columns now)
    for (let i = 0; i < 19; i++) {
        const cell = document.createElement('td');
        const input = document.createElement('input');
        input.type = 'text';
        input.className = 'cell-input';
        input.value = '';
        cell.appendChild(input);
        newRow.appendChild(cell);
    }
    
    tbody.appendChild(newRow);
    
    // Add event listeners to new inputs
    const newInputs = newRow.querySelectorAll('.cell-input');
    newInputs.forEach(input => {
        input.addEventListener('dblclick', function() {
            this.focus();
            this.select();
        });
    });
}

// Pagination functionality
let currentPage = 1;
let pageSize = 25;
let allData = [];

function goToFirstPage() {
    if (currentPage !== 1) {
        currentPage = 1;
        updatePagination();
        displayCurrentPage();
    }
}

function goToPreviousPage() {
    if (currentPage > 1) {
        currentPage--;
        updatePagination();
        displayCurrentPage();
    }
}

function goToNextPage() {
    const totalPages = Math.ceil(allData.length / pageSize);
    if (currentPage < totalPages) {
        currentPage++;
        updatePagination();
        displayCurrentPage();
    }
}

function goToLastPage() {
    const totalPages = Math.ceil(allData.length / pageSize);
    if (currentPage !== totalPages) {
        currentPage = totalPages;
        updatePagination();
        displayCurrentPage();
    }
}

function changePageSize() {
    pageSize = parseInt(document.getElementById('pageSize').value);
    currentPage = 1;
    updatePagination();
    displayCurrentPage();
}

function updatePagination() {
    const totalPages = Math.ceil(allData.length / pageSize);
    document.getElementById('currentPage').textContent = currentPage;
    document.getElementById('totalPages').textContent = totalPages;
    document.getElementById('totalRecords').textContent = allData.length;
    
    // Update button states
    document.querySelector('.pagination-btn[onclick="goToFirstPage()"]').disabled = currentPage === 1;
    document.querySelector('.pagination-btn[onclick="goToPreviousPage()"]').disabled = currentPage === 1;
    document.querySelector('.pagination-btn[onclick="goToNextPage()"]').disabled = currentPage === totalPages;
    document.querySelector('.pagination-btn[onclick="goToLastPage()"]').disabled = currentPage === totalPages;
}

function displayCurrentPage() {
    const tbody = document.querySelector('.excel-table tbody');
    tbody.innerHTML = '';
    
    const startIndex = (currentPage - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const pageData = allData.slice(startIndex, endIndex);
    
    pageData.forEach(request => {
        const row = document.createElement('tr');
        
        // Selection checkbox
        const checkboxCell = document.createElement('td');
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'row-checkbox';
        checkbox.value = request.id;
        checkbox.addEventListener('change', function() {
            toggleRowSelection(this);
        });
        checkboxCell.appendChild(checkbox);
        row.appendChild(checkboxCell);
        
        // ID
        const idCell = document.createElement('td');
        const idInput = document.createElement('input');
        idInput.type = 'text';
        idInput.className = 'cell-input';
        idInput.value = request.id;
        idInput.readOnly = true;
        idCell.appendChild(idInput);
        row.appendChild(idCell);
        
        // Company
        const companyCell = document.createElement('td');
        const companyInput = document.createElement('input');
        companyInput.type = 'text';
        companyInput.className = 'cell-input';
        companyInput.value = request.company;
        companyInput.readOnly = true;
        companyCell.appendChild(companyInput);
        row.appendChild(companyCell);
        
        // Customer
        const customerCell = document.createElement('td');
        const customerInput = document.createElement('input');
        customerInput.type = 'text';
        customerInput.className = 'cell-input';
        customerInput.value = request.customer;
        customerInput.readOnly = true;
        customerCell.appendChild(customerInput);
        row.appendChild(customerCell);
        
        // Governorate
        const governorateCell = document.createElement('td');
        const governorateInput = document.createElement('input');
        governorateInput.type = 'text';
        governorateInput.className = 'cell-input';
        governorateInput.value = request.governorate;
        governorateInput.readOnly = true;
        governorateCell.appendChild(governorateInput);
        row.appendChild(governorateCell);
        
        // City
        const cityCell = document.createElement('td');
        const cityInput = document.createElement('input');
        cityInput.type = 'text';
        cityInput.className = 'cell-input';
        cityInput.value = request.city;
        cityInput.readOnly = true;
        cityCell.appendChild(cityInput);
        row.appendChild(cityCell);
        
        // Category
        const categoryCell = document.createElement('td');
        const categoryInput = document.createElement('input');
        categoryInput.type = 'text';
        categoryInput.className = 'cell-input';
        categoryInput.value = request.category;
        categoryInput.readOnly = true;
        categoryCell.appendChild(categoryInput);
        row.appendChild(categoryCell);
        
        // Status
        const statusCell = document.createElement('td');
        statusCell.className = 'status-cell';
        statusCell.textContent = request.status;
        row.appendChild(statusCell);
        
        // Created By
        const createdByCell = document.createElement('td');
        const createdByInput = document.createElement('input');
        createdByInput.type = 'text';
        createdByInput.className = 'cell-input';
        createdByInput.value = request.createdBy;
        createdByInput.readOnly = true;
        createdByCell.appendChild(createdByInput);
        row.appendChild(createdByCell);
        
        // Created Date
        const createdDateCell = document.createElement('td');
        createdDateCell.className = 'date';
        createdDateCell.textContent = request.createdDate;
        row.appendChild(createdDateCell);
        
        // Closed Date
        const closedDateCell = document.createElement('td');
        closedDateCell.className = 'date';
        closedDateCell.textContent = request.closedDate;
        row.appendChild(closedDateCell);
        
        // Product
        const productCell = document.createElement('td');
        const productInput = document.createElement('input');
        productInput.type = 'text';
        productInput.className = 'cell-input';
        productInput.value = request.product;
        productInput.readOnly = true;
        productCell.appendChild(productInput);
        row.appendChild(productCell);
        
        // Size
        const sizeCell = document.createElement('td');
        const sizeInput = document.createElement('input');
        sizeInput.type = 'text';
        sizeInput.className = 'cell-input';
        sizeInput.value = request.size;
        sizeInput.readOnly = true;
        sizeCell.appendChild(sizeInput);
        row.appendChild(sizeCell);
        
        // Quantity
        const quantityCell = document.createElement('td');
        quantityCell.className = 'currency';
        quantityCell.textContent = request.quantity;
        row.appendChild(quantityCell);
        
        // Purchase Date
        const purchaseDateCell = document.createElement('td');
        purchaseDateCell.className = 'date';
        purchaseDateCell.textContent = request.purchaseDate;
        row.appendChild(purchaseDateCell);
        
        // Location
        const locationCell = document.createElement('td');
        const locationInput = document.createElement('input');
        locationInput.type = 'text';
        locationInput.className = 'cell-input';
        locationInput.value = request.location;
        locationInput.readOnly = true;
        locationCell.appendChild(locationInput);
        row.appendChild(locationCell);
        
        // Reason
        const reasonCell = document.createElement('td');
        const reasonInput = document.createElement('input');
        reasonInput.type = 'text';
        reasonInput.className = 'cell-input';
        reasonInput.value = request.reason;
        reasonInput.readOnly = true;
        reasonCell.appendChild(reasonInput);
        row.appendChild(reasonCell);
        
        // Inspected
        const inspectedCell = document.createElement('td');
        inspectedCell.className = 'status-cell';
        inspectedCell.textContent = request.inspected;
        row.appendChild(inspectedCell);
        
        // Inspection Date
        const inspectionDateCell = document.createElement('td');
        inspectionDateCell.className = 'date';
        inspectionDateCell.textContent = request.inspectionDate;
        row.appendChild(inspectionDateCell);
        
        // Client Approval
        const clientApprovalCell = document.createElement('td');
        clientApprovalCell.className = 'status-cell';
        clientApprovalCell.textContent = request.clientApproval;
        row.appendChild(clientApprovalCell);
        
        tbody.appendChild(row);
    });
}

// Make functions globally available
window.exportToCSV = exportToCSV;
window.addNewRow = addNewRow;
window.clearAllFilters = clearAllFilters;
window.toggleSelectAll = toggleSelectAll;
window.toggleRowSelection = toggleRowSelection;
window.goToFirstPage = goToFirstPage;
window.goToPreviousPage = goToPreviousPage;
window.goToNextPage = goToNextPage;
window.goToLastPage = goToLastPage;
window.changePageSize = changePageSize;
