// Sample Maintenance Request Data for Excel Table
const sampleMaintenanceData = [
    {
        id: "5428",
        company: "janssen",
        customer: "محمد عبد الشافى ابراهيم",
        governorate: "القاهرة",
        city: "عين شمس",
        category: "طلب صيانه",
        status: "in_progress",
        createdBy: "يوسف",
        createdDate: "2025-08-10",
        closedDate: "-",
        product: "الماني",
        size: "0*120*25",
        quantity: "2",
        purchaseDate: "2016-12-31",
        location: "",
        reason: "هبوط",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5429",
        company: "janssen",
        customer: "أحمد محمد علي",
        governorate: "الإسكندرية",
        city: "سموحة",
        category: "طلب صيانه",
        status: "completed",
        createdBy: "علي",
        createdDate: "2025-08-09",
        closedDate: "2025-08-12",
        product: "إيطالي",
        size: "0*100*20",
        quantity: "1",
        purchaseDate: "2015-06-15",
        location: "محل البناء",
        reason: "كسر",
        inspected: "Yes",
        inspectionDate: "2025-08-11",
        clientApproval: "Yes"
    },
    {
        id: "5430",
        company: "janssen",
        customer: "فاطمة أحمد",
        governorate: "الجيزة",
        city: "الدقي",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "محمود",
        createdDate: "2025-08-08",
        closedDate: "-",
        product: "صيني",
        size: "0*80*15",
        quantity: "3",
        purchaseDate: "2017-03-22",
        location: "سوق الخردة",
        reason: "صدأ",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5431",
        company: "janssen",
        customer: "عبد الرحمن حسن",
        governorate: "أسيوط",
        city: "أسيوط",
        category: "طلب صيانه",
        status: "in_progress",
        createdBy: "أحمد",
        createdDate: "2025-08-07",
        closedDate: "-",
        product: "الماني",
        size: "0*150*30",
        quantity: "1",
        purchaseDate: "2014-09-10",
        location: "مصنع الخرسانة",
        reason: "تآكل",
        inspected: "Yes",
        inspectionDate: "2025-08-08",
        clientApproval: "No"
    },
    {
        id: "5432",
        company: "janssen",
        customer: "سارة محمود",
        governorate: "المنوفية",
        city: "شبين الكوم",
        category: "طلب صيانه",
        status: "completed",
        createdBy: "محمد",
        createdDate: "2025-08-06",
        closedDate: "2025-08-10",
        product: "إيطالي",
        size: "0*90*18",
        quantity: "2",
        purchaseDate: "2016-01-20",
        location: "ورشة النجارة",
        reason: "انكسار",
        inspected: "Yes",
        inspectionDate: "2025-08-07",
        clientApproval: "Yes"
    },
    {
        id: "5433",
        company: "janssen",
        customer: "خالد عبد الله",
        governorate: "سوهاج",
        city: "سوهاج",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "علي",
        createdDate: "2025-08-05",
        closedDate: "-",
        product: "صيني",
        size: "0*70*12",
        quantity: "4",
        purchaseDate: "2018-07-15",
        location: "مستودع الأدوات",
        reason: "صدأ",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5434",
        company: "janssen",
        customer: "نور الدين",
        governorate: "قنا",
        city: "قنا",
        category: "طلب صيانه",
        status: "in_progress",
        createdBy: "يوسف",
        createdDate: "2025-08-04",
        closedDate: "-",
        product: "الماني",
        size: "0*110*22",
        quantity: "1",
        purchaseDate: "2015-11-30",
        location: "مشروع السد",
        reason: "هبوط",
        inspected: "Yes",
        inspectionDate: "2025-08-05",
        clientApproval: "No"
    },
    {
        id: "5435",
        company: "janssen",
        customer: "مريم أحمد",
        governorate: "الأقصر",
        city: "الأقصر",
        category: "طلب صيانه",
        status: "completed",
        createdBy: "محمود",
        createdDate: "2025-08-03",
        closedDate: "2025-08-07",
        product: "إيطالي",
        size: "0*95*19",
        quantity: "3",
        purchaseDate: "2016-04-12",
        location: "مشروع السياحة",
        reason: "كسر",
        inspected: "Yes",
        inspectionDate: "2025-08-04",
        clientApproval: "Yes"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5437",
        company: "janssen",
        customer: "فاطمة علي",
        governorate: "بني سويف",
        city: "بني سويف",
        category: "طلب صيانه",
        status: "in_progress",
        createdBy: "محمد",
        createdDate: "2025-08-01",
        closedDate: "-",
        product: "الماني",
        size: "0*130*28",
        quantity: "1",
        purchaseDate: "2014-12-05",
        location: "مصنع الأسمنت",
        reason: "هبوط",
        inspected: "Yes",
        inspectionDate: "2025-08-02",
        clientApproval: "No"
    }
];

// Function to populate table with maintenance data
function populateTableWithMaintenanceData() {
    // Store all data globally for pagination
    allData = sampleMaintenanceData;
    
    // Initialize pagination
    currentPage = 1;
    pageSize = parseInt(document.getElementById('pageSize').value) || 25;
    
    // Update pagination info and display first page
    updatePagination();
    displayCurrentPage();
    
    // Add event listeners to inputs
    addEventListenersToInputs();
}



// Function to add event listeners to input fields
function addEventListenersToInputs() {
    document.querySelectorAll('.cell-input').forEach(input => {
        input.addEventListener('dblclick', function() {
            if (!this.readOnly) {
                this.focus();
                this.select();
            }
        });
    });
}

// Function to get maintenance data
function getMaintenanceData() {
    return sampleMaintenanceData;
}

// Function to add new maintenance request
function addNewMaintenanceRequest(requestData) {
    sampleMaintenanceData.push(requestData);
    populateTableWithMaintenanceData();
}

// Function to clear all data
function clearAllData() {
    sampleMaintenanceData.length = 0;
    populateTableWithMaintenanceData();
}

// Function to reset to original sample data
function resetToOriginalData() {
    populateTableWithMaintenanceData();
}

// Function to toggle row selection
function toggleRowSelection(checkbox) {
    const row = checkbox.closest('tr');
    if (checkbox.checked) {
        row.classList.add('selected');
    } else {
        row.classList.remove('selected');
    }
}

// Make functions globally available
window.populateTableWithMaintenanceData = populateTableWithMaintenanceData;
window.getMaintenanceData = getMaintenanceData;
window.addNewMaintenanceRequest = addNewMaintenanceRequest;
window.clearAllData = clearAllData;
window.resetToOriginalData = resetToOriginalData;
