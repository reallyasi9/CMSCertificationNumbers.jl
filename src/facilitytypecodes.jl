const _MEDICAID_FACILITY_CODES = Dict{Char, String}(
    .=>(('A', 'B'), "NF (Formerly assigned to Medicaid SNF)")...,
    .=>(('E', 'F'), "NF (Formerly assigned to ICF)")...,
    .=>(('G', 'H'), "ICF/IID")...,
    .=>(('J',), "Medicaid-Only Hospital")...,
    .=>(('K',), "Medicaid HHA")...,
    .=>(('L',), "Psychiatric Residential Treatment Facility (PRTF)")...,
    .=>(('M',), "Psychiatric Unit of a CAH")...,
    .=>(('R',), "Rehabilitation Unit of a CAH")...,
    .=>(('S',), "Psychiatric Unit")...,
    .=>(('T',), "Rehabilitation Unit")...,
    .=>(('U',), "Swing-Bed Approval for Short-Term Hospital")...,
    .=>(('W',), "Swing-Bed Approval for Long-Term Care Hospital")...,
    .=>(('Z',), "Swing-Bed Approval for CAH")...,
)

const _MEDICAID_HOSPITAL_RANGES = [
    001:099 => "Short-term Acute Care Hospital",
    100:199 => "Children's Hospital",
    200:299 => "Children's Psychiatric Hospital",
    300:399 => "Psychiatric Hospital",
    400:499 => "Rehabilitation Hospital",
    500:599 => "Long-term Hospital",
]

const _FACILITY_RANGES = [
    0001:0879 => "Short-term (General and Specialty) Hospital",
    0880:0899 => "Hospital participating in ORD demonstration project",
    0900:0999 => "Multiple Hospital Component in a Medical Complex (Number Retired)",
    1000:1199 => "Federally Qualified Health Center",
    1200:1224 => "Alcohol/Drug Hospital (Number Retired)",
    1225:1299 => "Medical Assistance Facility",
    1300:1399 => "Critical Access Hospital",
    1400:1499 => "Community Mental Health Center",
    1500:1799 => "Hospice",
    1800:1989 => "Federally Qualified Health Center",
    1990:1999 => "Religious Non-medical Health Care Institution (formerly Christian Science Sanatoria Hospital Services)",
    2000:2299 => "Long-Term Care Hospital",
    2300:2499 => "Hospital-based Renal Dialysis Facility",
    2500:2899 => "Independent Renal Dialysis Facility",
    2900:2999 => "Independent Special Purpose Renal Dialysis Facility",
    3000:3024 => "Tuberculosis Hospital (Number Retired)",
    3025:3099 => "Rehabilitation Hospital",
    3100:3199 => "Home Health Agency",
    3200:3299 => "Comprehensive Outpatient Rehabilitation Facility",
    3300:3399 => "Children's Hospital",
    3400:3499 => "Rural Health Clinic (Provider-based)",
    3500:3699 => "Hospital-based Satellite Renal Dialysis Facility",
    3700:3799 => "Hospital-based Special Purpose Renal Dialysis Facility",
    3800:3974 => "Rural Health Clinic (Free-standing)",
    3975:3999 => "Rural Health Clinic (Provider-based)",
    4000:4499 => "Psychiatric Hospital",
    4500:4599 => "Comprehensive Outpatient Rehabilitation Facility",
    4600:4799 => "Community Mental Health Center",
    4800:4899 => "Comprehensive Outpatient Rehabilitation Facility",
    4900:4999 => "Community Mental Health Center",
    5000:6499 => "Skilled Nursing Facility",
    6500:6989 => "Outpatient Physical Therapy Services",
    6990:6999 => "Number Reserved (formerly Christian Science Sanatoria Skilled Nursing Services)",
    7000:8499 => "Home Health Agency",
    8500:8899 => "Rural Health Clinic (Provider-based)",
    8900:8999 => "Rural Health Clinic (Free-standing)",
    9000:9799 => "Home Health Agency",
    9800:9899 => "Transplant Center",
    9900:9999 => "Reserved for Future Use",
]

const _EMERGENCY_CODES = Dict{Char, String}(
    'E' => "Non-Federal Emergency Hospital",
    'F' => "Federal Emergency Hospital",
)

const _MEDICAID_TYPE_CODES = ('A', 'B', 'E', 'F', 'G', 'H', 'K', 'L', 'J')
const _IPPS_EXCLUDED_TYPE_CODES = ('M', 'R', 'S', 'T', 'U', 'W', 'Z')

const _IPPS_PARENT_HOSPITAL_TYPES = Dict{Char, Pair{String, String}}(
    'A' => ("LTCH" => "20"),
    'B' => ("LTCH" => "21"),
    'C' => ("LTCH" => "22"),
    'D' => ("Rehabilitation Hospital" => "30"),
    'E' => ("Children's Hospital" => "33"),
    'F' => ("Psychiatric Hospital" => "40"),
    'G' => ("Psychiatric Hospital" => "41"),
    'H' => ("Psychiatric Hospital" => "42"),
    'J' => ("Psychiatric Hospital" => "43"),
    'K' => ("Psychiatric Hospital" => "44"),
)
