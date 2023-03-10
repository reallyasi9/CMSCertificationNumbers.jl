using CMSCertificationNumbers
using CSV
using Test

@testset "CMSCertificationNumbers.jl" begin
    @testset "MedicareProviderCCN" begin
        @testset "constructor" begin
            @test MedicareProviderCCN("123456").number == "123456"
            @test MedicareProviderCCN("QWERTYU").number == "QWERTYU" # invalid, but direct constructor allows this
            # Doesn't fit within String7 size
            @test_throws ArgumentError MedicareProviderCCN("12345678")
        end
        @testset "convert" begin
            @test convert(MedicareProviderCCN, "123456") == MedicareProviderCCN("123456")
            @test convert(MedicareProviderCCN, 123456) == MedicareProviderCCN("123456")
            @test convert(MedicareProviderCCN, 123456.0) == MedicareProviderCCN("123456")
        end
        @testset "parse" begin
            @test parse(MedicareProviderCCN, "123456") == MedicareProviderCCN("123456")
            @test tryparse(MedicareProviderCCN, "123456") == MedicareProviderCCN("123456")
            @test_throws ArgumentError parse(MedicareProviderCCN, "123456789")
            @test tryparse(MedicareProviderCCN, "123456789") === nothing
        end
        @testset "ccn function" begin
            # strings
            @test ccn(MedicareProviderCCN, "123456") == MedicareProviderCCN("123456")
            @test ccn(MedicareProviderCCN, "QWERTY") == MedicareProviderCCN("QWERTY")
            @test ccn(MedicareProviderCCN, "") == MedicareProviderCCN("000000")
            @test ccn(MedicareProviderCCN, "1") == MedicareProviderCCN("000001")
            # Too many characters
            @test_throws ArgumentError ccn(MedicareProviderCCN, "QWERTYU")

            # integers
            @test ccn(MedicareProviderCCN, 123456) == MedicareProviderCCN("123456")
            @test ccn(MedicareProviderCCN, 1) == MedicareProviderCCN("000001")
            # Too many digits
            @test_throws ArgumentError ccn(MedicareProviderCCN, 1234567)
            # Negative value
            @test_throws ArgumentError ccn(MedicareProviderCCN, -1)
            
            # other numbers
            @test ccn(MedicareProviderCCN, 1.0) == MedicareProviderCCN("000001")
            @test ccn(MedicareProviderCCN, Rational(5, 5)) == MedicareProviderCCN("000001")
            # Inexact
            @test_throws InexactError ccn(MedicareProviderCCN, 1.00000001)
        end
        @testset "string and repr" begin
            @test string(MedicareProviderCCN("123456")) == "123456"
            @test repr(MIME("text/plain"), MedicareProviderCCN("123456")) == "MedicareProviderCCN(\"123456\")"
        end
        @testset "isvalid" begin
            @test isvalid(MedicareProviderCCN("123456"))
            @test [isvalid(MedicareProviderCCN("123456"), i) for i in 1:6] == fill(true, 6)
            @test isvalid(MedicareProviderCCN("12P456"))
            @test [isvalid(MedicareProviderCCN("12P456"), i) for i in 1:6] == fill(true, 6)
            # Too many characters
            @test !isvalid(MedicareProviderCCN("1234567"))
            @test [isvalid(MedicareProviderCCN("1234567"), i) for i in 1:7] == [true, true, true, true, true, true, false]
            # Not enough characters
            @test !isvalid(MedicareProviderCCN("12345"))
            @test [isvalid(MedicareProviderCCN("12345"), i) for i in 1:5] == fill(true, 5)
            # Invalid state code
            @test !isvalid(MedicareProviderCCN("XX3456"))
            @test [isvalid(MedicareProviderCCN("XX3456"), i) for i in 1:6] == [false, false, true, true, true, true]
            # Invalid type code (lower case)
            @test !isvalid(MedicareProviderCCN("12p456"))
            @test [isvalid(MedicareProviderCCN("12p456"), i) for i in 1:6] == [true, true, false, true, true, true]
            # Invalid type code (non-digit, not 'P')
            @test !isvalid(MedicareProviderCCN("12A456"))
            @test [isvalid(MedicareProviderCCN("12A456"), i) for i in 1:6] == [true, true, false, true, true, true]
            # Invalid sequence number (non-digit)
            @test !isvalid(MedicareProviderCCN("12345E"))
            @test [isvalid(MedicareProviderCCN("12345E"), i) for i in 1:6] == [true, true, true, true, true, false]
        end
        @testset "decode" begin
            @test state_code(MedicareProviderCCN("123456")) == "12"
            @test state_code(MedicareProviderCCN("XX3456")) == "XX"
            @test state(MedicareProviderCCN("123456")) == "Hawaii"
            @test state(MedicareProviderCCN("XX3456")) == CMSCertificationNumbers.INVALID_STATE

            @test facility_type_code(MedicareProviderCCN("123456")) == "3400-3499"
            @test facility_type_code(MedicareProviderCCN("12P456")) == "P"
            @test_throws ArgumentError facility_type_code(MedicareProviderCCN("12X456"))
            @test facility_type(MedicareProviderCCN("123456")) == "Rural Health Clinic (Provider-based)"
            @test facility_type(MedicareProviderCCN("12P456")) == "Organ Procurement Organization (OPO)"
            @test facility_type(MedicareProviderCCN("12X456")) == CMSCertificationNumbers.INVALID_FACILITY_TYPE

            @test sequence_number(MedicareProviderCCN("123456")) == 56
            @test sequence_number(MedicareProviderCCN("12P456")) == 456
            @test sequence_number(MedicareProviderCCN("128600")) == 100
            @test_throws ArgumentError sequence_number(MedicareProviderCCN("12XXXX"))

            @test decode(MedicareProviderCCN("123456")) == "123456: Medicare Provider in Hawaii [12] Rural Health Clinic (Provider-based) [3400-3499] sequence number 56"
            @test decode(MedicareProviderCCN("XX3456")) == "XX3456: Medicare Provider in invalid state [XX] Rural Health Clinic (Provider-based) [3400-3499] sequence number 56"
            @test decode(MedicareProviderCCN("12P456")) == "12P456: Medicare Provider in Hawaii [12] Organ Procurement Organization (OPO) [P] sequence number 456"
            @test decode(MedicareProviderCCN("120000")) == "120000: Medicare Provider in Hawaii [12] invalid facility type [0000] sequence number 0"
            @test_throws ArgumentError decode(MedicareProviderCCN("12X456"))
            @test_throws ArgumentError decode(MedicareProviderCCN("123XXX"))
        end
    end

    @testset "MedicaidOnlyProviderCCN" begin
        @testset "constructor" begin
            @test MedicaidOnlyProviderCCN("12A456").number == "12A456"
            @test MedicaidOnlyProviderCCN("QWERTYU").number == "QWERTYU" # invalid, but direct constructor allows this
            # Doesn't fit within String7 size
            @test_throws ArgumentError MedicaidOnlyProviderCCN("12A45678")
        end
        @testset "convert" begin
            @test convert(MedicaidOnlyProviderCCN, "12A456") == MedicaidOnlyProviderCCN("12A456")
        end
        @testset "parse" begin
            @test parse(MedicaidOnlyProviderCCN, "12A456") == MedicaidOnlyProviderCCN("12A456")
            @test tryparse(MedicaidOnlyProviderCCN, "12A456") == MedicaidOnlyProviderCCN("12A456")
            @test_throws ArgumentError parse(MedicaidOnlyProviderCCN, "12A456789")
            @test tryparse(MedicaidOnlyProviderCCN, "12A456789") === nothing
        end
        @testset "ccn function" begin
            # strings
            @test ccn(MedicaidOnlyProviderCCN, "12A456") == MedicaidOnlyProviderCCN("12A456")
            @test ccn(MedicaidOnlyProviderCCN, "QWERTY") == MedicaidOnlyProviderCCN("QWERTY")
            @test ccn(MedicaidOnlyProviderCCN, "") == MedicaidOnlyProviderCCN("000000")
            @test ccn(MedicaidOnlyProviderCCN, "1") == MedicaidOnlyProviderCCN("000001")
            # Too many characters
            @test_throws ArgumentError ccn(MedicaidOnlyProviderCCN, "QWERTYU")
        end
        @testset "string and repr" begin
            @test string(MedicaidOnlyProviderCCN("12A456")) == "12A456"
            @test repr(MIME("text/plain"), MedicaidOnlyProviderCCN("12A456")) == "MedicaidOnlyProviderCCN(\"12A456\")"
        end
        @testset "isvalid" begin
            @test isvalid(MedicaidOnlyProviderCCN("12A456"))
            @test [isvalid(MedicaidOnlyProviderCCN("12A456"), i) for i in 1:6] == fill(true, 6)
            # Too many characters
            @test !isvalid(MedicaidOnlyProviderCCN("12A4567"))
            @test [isvalid(MedicaidOnlyProviderCCN("12A4567"), i) for i in 1:7] == [true, true, true, true, true, true, false]
            # Not enough characters
            @test !isvalid(MedicaidOnlyProviderCCN("12A45"))
            @test [isvalid(MedicaidOnlyProviderCCN("12A45"), i) for i in 1:5] == fill(true, 5) # all characters are valid
            # Invalid state code
            @test !isvalid(MedicaidOnlyProviderCCN("XXA456"))
            @test [isvalid(MedicaidOnlyProviderCCN("XXA456"), i) for i in 1:6] == [false, false, true, true, true, true]
            # Invalid type code (lower case)
            @test !isvalid(MedicaidOnlyProviderCCN("12a456"))
            @test [isvalid(MedicaidOnlyProviderCCN("12a456"), i) for i in 1:6] == [true, true, false, true, true, true]
            # Invalid type code
            @test !isvalid(MedicaidOnlyProviderCCN("12P456"))
            @test [isvalid(MedicaidOnlyProviderCCN("12P456"), i) for i in 1:6] == [true, true, false, true, true, true]
            # Invalid sequence number (non-digit)
            @test !isvalid(MedicaidOnlyProviderCCN("12A45E"))
            @test [isvalid(MedicaidOnlyProviderCCN("12A45E"), i) for i in 1:6] == [true, true, true, true, true, false]
        end
        @testset "decode" begin
            @test state_code(MedicaidOnlyProviderCCN("12A456")) == "12"
            @test state_code(MedicaidOnlyProviderCCN("XXA456")) == "XX"
            @test state(MedicaidOnlyProviderCCN("12A456")) == "Hawaii"
            @test state(MedicaidOnlyProviderCCN("XX3456")) == CMSCertificationNumbers.INVALID_STATE

            @test facility_type_code(MedicaidOnlyProviderCCN("12A456")) == "A"
            @test facility_type(MedicaidOnlyProviderCCN("12A456")) == "NF (Formerly assigned to Medicaid SNF)"
            @test facility_type(MedicaidOnlyProviderCCN("12X456")) == CMSCertificationNumbers.INVALID_FACILITY_TYPE

            @test sequence_number(MedicaidOnlyProviderCCN("12A456")) == 456
            @test_throws ArgumentError sequence_number(MedicaidOnlyProviderCCN("12XXXX"))

            @test decode(MedicaidOnlyProviderCCN("12A456")) == "12A456: Medicaid-only Provider in Hawaii [12] NF (Formerly assigned to Medicaid SNF) [A] sequence number 456"
            @test decode(MedicaidOnlyProviderCCN("XXA456")) == "XXA456: Medicaid-only Provider in invalid state [XX] NF (Formerly assigned to Medicaid SNF) [A] sequence number 456"
            @test decode(MedicaidOnlyProviderCCN("120000")) == "120000: Medicaid-only Provider in Hawaii [12] invalid facility type [0] sequence number 0"
            @test_throws ArgumentError decode(MedicaidOnlyProviderCCN("123XXX"))
        end
    end

    @testset "IPPSExcludedProviderCCN" begin
        @testset "constructor" begin
            @test IPPSExcludedProviderCCN("12M456").number == "12M456"
            @test IPPSExcludedProviderCCN("QWERTYU").number == "QWERTYU" # invalid, but direct constructor allows this
            # Doesn't fit within String7 size
            @test_throws ArgumentError IPPSExcludedProviderCCN("12M45678")
        end
        @testset "convert" begin
            @test convert(IPPSExcludedProviderCCN, "12M456") == IPPSExcludedProviderCCN("12M456")
        end
        @testset "parse" begin
            @test parse(IPPSExcludedProviderCCN, "12M456") == IPPSExcludedProviderCCN("12M456")
            @test tryparse(IPPSExcludedProviderCCN, "12M456") == IPPSExcludedProviderCCN("12M456")
            @test_throws ArgumentError parse(IPPSExcludedProviderCCN, "12M456789")
            @test tryparse(IPPSExcludedProviderCCN, "12M456789") === nothing
        end
        @testset "ccn function" begin
            # strings
            @test ccn(IPPSExcludedProviderCCN, "12M456") == IPPSExcludedProviderCCN("12M456")
            @test ccn(IPPSExcludedProviderCCN, "QWERTY") == IPPSExcludedProviderCCN("QWERTY")
            @test ccn(IPPSExcludedProviderCCN, "") == IPPSExcludedProviderCCN("000000")
            @test ccn(IPPSExcludedProviderCCN, "1") == IPPSExcludedProviderCCN("000001")
            # Too many characters
            @test_throws ArgumentError ccn(IPPSExcludedProviderCCN, "QWERTYU")
        end
        @testset "string and repr" begin
            @test string(IPPSExcludedProviderCCN("12M456")) == "12M456"
            @test repr(MIME("text/plain"), IPPSExcludedProviderCCN("12M456")) == "IPPSExcludedProviderCCN(\"12M456\")"
        end
        @testset "isvalid" begin
            @test isvalid(IPPSExcludedProviderCCN("12M456"))
            @test [isvalid(IPPSExcludedProviderCCN("12M456"), i) for i in 1:6] == fill(true, 6)
            # Too many characters
            @test !isvalid(IPPSExcludedProviderCCN("12M4567"))
            @test [isvalid(IPPSExcludedProviderCCN("12M4567"), i) for i in 1:7] == [true, true, true, true, true, true, false]
            # Not enough characters
            @test !isvalid(IPPSExcludedProviderCCN("12M45"))
            @test [isvalid(IPPSExcludedProviderCCN("12M45"), i) for i in 1:5] == fill(true, 5) # all characters are valid
            # Invalid state code
            @test !isvalid(IPPSExcludedProviderCCN("XXM456"))
            @test [isvalid(IPPSExcludedProviderCCN("XXM456"), i) for i in 1:6] == [false, false, true, true, true, true]
            # Invalid type code (lower case)
            @test !isvalid(IPPSExcludedProviderCCN("12m456"))
            @test [isvalid(IPPSExcludedProviderCCN("12m456"), i) for i in 1:6] == [true, true, false, true, true, true]
            # Invalid type code
            @test !isvalid(IPPSExcludedProviderCCN("12A456"))
            @test [isvalid(IPPSExcludedProviderCCN("12A456"), i) for i in 1:6] == [true, true, false, true, true, true]
            # Invalid sequence number (non-digit)
            @test !isvalid(IPPSExcludedProviderCCN("12M45E"))
            @test [isvalid(IPPSExcludedProviderCCN("12M45E"), i) for i in 1:6] == [true, true, true, true, true, false]
        end
        @testset "decode" begin
            @test state_code(IPPSExcludedProviderCCN("12M456")) == "12"
            @test state_code(IPPSExcludedProviderCCN("XXA456")) == "XX"
            @test state(IPPSExcludedProviderCCN("12M456")) == "Hawaii"
            @test state(IPPSExcludedProviderCCN("XX3456")) == CMSCertificationNumbers.INVALID_STATE

            @test facility_type_code(IPPSExcludedProviderCCN("12M456")) == "M"
            @test facility_type(IPPSExcludedProviderCCN("12M456")) == "Psychiatric Unit of a CAH"
            @test facility_type(IPPSExcludedProviderCCN("12X456")) == CMSCertificationNumbers.INVALID_FACILITY_TYPE

            @test sequence_number(IPPSExcludedProviderCCN("12M456")) == 456
            @test_throws ArgumentError sequence_number(IPPSExcludedProviderCCN("12XXXX"))

            @test decode(IPPSExcludedProviderCCN("12M456")) == "12M456: IPPS-Excluded Provider in Hawaii [12] Psychiatric Unit of a CAH [M] of parent with sequence number 456"
            @test decode(IPPSExcludedProviderCCN("XXM456")) == "XXM456: IPPS-Excluded Provider in invalid state [XX] Psychiatric Unit of a CAH [M] of parent with sequence number 456"
            @test decode(IPPSExcludedProviderCCN("120000")) == "120000: IPPS-Excluded Provider in Hawaii [12] invalid facility type [0] of parent with sequence number 0"
            @test decode(IPPSExcludedProviderCCN("12MA56")) == "12MA56: IPPS-Excluded Provider in Hawaii [12] Psychiatric Unit of a CAH [M] of parent LTCH [A] with sequence number 2056"
            @test_throws ArgumentError decode(IPPSExcludedProviderCCN("12MXXX"))
        end
    end

    @testset "EmergencyHospitalCCN" begin
        @testset "constructor" begin
            @test EmergencyHospitalCCN("12345E").number == "12345E"
            @test EmergencyHospitalCCN("QWERTYU").number == "QWERTYU" # invalid, but direct constructor allows this
            # Doesn't fit within String7 size
            @test_throws ArgumentError EmergencyHospitalCCN("12345E78")
        end
        @testset "convert" begin
            @test convert(EmergencyHospitalCCN, "12345E") == EmergencyHospitalCCN("12345E")
        end
        @testset "parse" begin
            @test parse(EmergencyHospitalCCN, "12345E") == EmergencyHospitalCCN("12345E")
            @test tryparse(EmergencyHospitalCCN, "12345E") == EmergencyHospitalCCN("12345E")
            @test_throws ArgumentError parse(EmergencyHospitalCCN, "12345E789")
            @test tryparse(EmergencyHospitalCCN, "12345E789") === nothing
        end
        @testset "ccn function" begin
            # strings
            @test ccn(EmergencyHospitalCCN, "12345E") == EmergencyHospitalCCN("12345E")
            @test ccn(EmergencyHospitalCCN, "QWERTY") == EmergencyHospitalCCN("QWERTY")
            @test ccn(EmergencyHospitalCCN, "") == EmergencyHospitalCCN("000000")
            @test ccn(EmergencyHospitalCCN, "1") == EmergencyHospitalCCN("000001")
            # Too many characters
            @test_throws ArgumentError ccn(EmergencyHospitalCCN, "QWERTYU")
        end
        @testset "string and repr" begin
            @test string(EmergencyHospitalCCN("12345E")) == "12345E"
            @test repr(MIME("text/plain"), EmergencyHospitalCCN("12345E")) == "EmergencyHospitalCCN(\"12345E\")"
        end
        @testset "isvalid" begin
            @test isvalid(EmergencyHospitalCCN("12345E"))
            @test [isvalid(EmergencyHospitalCCN("12345E"), i) for i in 1:6] == fill(true, 6)
            # Too many characters
            @test !isvalid(EmergencyHospitalCCN("12345E7"))
            @test [isvalid(EmergencyHospitalCCN("12345E7"), i) for i in 1:7] == [true, true, true, true, true, true, false]
            # Not enough characters
            @test !isvalid(EmergencyHospitalCCN("12345"))
            @test [isvalid(EmergencyHospitalCCN("12345"), i) for i in 1:5] == fill(true, 5) # all characters are valid
            # Invalid state code
            @test !isvalid(EmergencyHospitalCCN("XX345E"))
            @test [isvalid(EmergencyHospitalCCN("XX345E"), i) for i in 1:6] == [false, false, true, true, true, true]
            # Invalid type code (lower case)
            @test !isvalid(EmergencyHospitalCCN("12345e"))
            @test [isvalid(EmergencyHospitalCCN("12345e"), i) for i in 1:6] == [true, true, true, true, true, false]
            # Invalid type code
            @test !isvalid(EmergencyHospitalCCN("12345X"))
            @test [isvalid(EmergencyHospitalCCN("12345X"), i) for i in 1:6] == [true, true, true, true, true, false]
            # Invalid sequence number (non-digit)
            @test !isvalid(EmergencyHospitalCCN("1234XE"))
            @test [isvalid(EmergencyHospitalCCN("1234XE"), i) for i in 1:6] == [true, true, true, true, false, true]
        end
        @testset "decode" begin
            @test state_code(EmergencyHospitalCCN("12345E")) == "12"
            @test state_code(EmergencyHospitalCCN("XX345E")) == "XX"
            @test state(EmergencyHospitalCCN("12345E")) == "Hawaii"
            @test state(EmergencyHospitalCCN("XX345E")) == CMSCertificationNumbers.INVALID_STATE

            @test facility_type_code(EmergencyHospitalCCN("12345E")) == "E"
            @test facility_type(EmergencyHospitalCCN("12345E")) == "Non-Federal Emergency Hospital"
            @test facility_type(EmergencyHospitalCCN("12345X")) == CMSCertificationNumbers.INVALID_FACILITY_TYPE

            @test sequence_number(EmergencyHospitalCCN("12345E")) == 345
            @test_throws ArgumentError sequence_number(EmergencyHospitalCCN("12XXXE"))

            @test decode(EmergencyHospitalCCN("12345E")) == "12345E: Emergency Hospital in Hawaii [12] Non-Federal Emergency Hospital [E] sequence number 345"
            @test decode(EmergencyHospitalCCN("XX345E")) == "XX345E: Emergency Hospital in invalid state [XX] Non-Federal Emergency Hospital [E] sequence number 345"
            @test decode(EmergencyHospitalCCN("120000")) == "120000: Emergency Hospital in Hawaii [12] invalid facility type [0] sequence number 0"
            @test_throws ArgumentError decode(EmergencyHospitalCCN("12XXXE"))
        end
    end

    @testset "SupplierCCN" begin
        @testset "constructor" begin
            @test SupplierCCN("12C4567890").number == "12C4567890"
            @test SupplierCCN("QWERTY").number == "QWERTY" # invalid, but direct constructor allows this
            # Doesn't fit within String15 size
            @test_throws ArgumentError SupplierCCN("12C4567890123456")
        end
        @testset "convert" begin
            @test convert(SupplierCCN, "12C4567890") == SupplierCCN("12C4567890")
        end
        @testset "parse" begin
            @test parse(SupplierCCN, "12C4567890") == SupplierCCN("12C4567890")
            @test tryparse(SupplierCCN, "12C4567890") == SupplierCCN("12C4567890")
            @test_throws ArgumentError parse(SupplierCCN, "12C4567890123456")
            @test tryparse(SupplierCCN, "12C4567890123456") === nothing
        end
        @testset "ccn function" begin
            # strings
            @test ccn(SupplierCCN, "12C4567890") == SupplierCCN("12C4567890")
            @test ccn(SupplierCCN, "QWERTYUIOP") == SupplierCCN("QWERTYUIOP")
            @test ccn(SupplierCCN, "") == SupplierCCN("0000000000")
            @test ccn(SupplierCCN, "1") == SupplierCCN("0000000001")
            # Too many characters
            @test_throws ArgumentError ccn(SupplierCCN, "QWERTYUIOPASDFGH")
        end
        @testset "string and repr" begin
            @test string(SupplierCCN("12C4567890")) == "12C4567890"
            @test repr(MIME("text/plain"), SupplierCCN("12C4567890")) == "SupplierCCN(\"12C4567890\")"
        end
        @testset "isvalid" begin
            @test isvalid(SupplierCCN("12C4567890"))
            @test [isvalid(SupplierCCN("12C4567890"), i) for i in 1:10] == fill(true, 10)
            # Too many characters
            @test !isvalid(SupplierCCN("12C45678901"))
            @test [isvalid(SupplierCCN("12C45678901"), i) for i in 1:11] == [true, true, true, true, true, true, true, true, true, true, false]
            # Not enough characters
            @test !isvalid(SupplierCCN("12C456789"))
            @test [isvalid(SupplierCCN("12C456789"), i) for i in 1:9] == fill(true, 9) # all characters are valid
            # Invalid state code
            @test !isvalid(SupplierCCN("XXC4567890"))
            @test [isvalid(SupplierCCN("XXC4567890"), i) for i in 1:10] == [false, false, true, true, true, true, true, true, true, true]
            # Invalid type code (lower case)
            @test !isvalid(SupplierCCN("12c4567890"))
            @test [isvalid(SupplierCCN("12c4567890"), i) for i in 1:10] == [true, true, false, true, true, true, true, true, true, true]
            # Invalid type code
            @test !isvalid(SupplierCCN("1234567890"))
            @test [isvalid(SupplierCCN("1234567890"), i) for i in 1:10] == [true, true, false, true, true, true, true, true, true, true]
            # Invalid sequence number (non-digit)
            @test !isvalid(SupplierCCN("12C456789X"))
            @test [isvalid(SupplierCCN("12C456789X"), i) for i in 1:10] == [true, true, true, true, true, true, true, true, true, false]
        end
        @testset "decode" begin
            @test state_code(SupplierCCN("12C4567890")) == "12"
            @test state_code(SupplierCCN("XXC4567890")) == "XX"
            @test state(SupplierCCN("12C4567890")) == "Hawaii"
            @test state(SupplierCCN("XXC4567890")) == CMSCertificationNumbers.INVALID_STATE

            @test facility_type_code(SupplierCCN("12C4567890")) == "C"
            @test facility_type(SupplierCCN("12C4567890")) == "Ambulatory Surgical Center"
            @test facility_type(SupplierCCN("12345X")) == CMSCertificationNumbers.INVALID_FACILITY_TYPE

            @test sequence_number(SupplierCCN("12C4567890")) == 4567890
            @test_throws ArgumentError sequence_number(SupplierCCN("12CXXXXXXX"))

            @test decode(SupplierCCN("12C4567890")) == "12C4567890: Supplier in Hawaii [12] Ambulatory Surgical Center [C] sequence number 4567890"
            @test decode(SupplierCCN("XXC4567890")) == "XXC4567890: Supplier in invalid state [XX] Ambulatory Surgical Center [C] sequence number 4567890"
            @test decode(SupplierCCN("1200000000")) == "1200000000: Supplier in Hawaii [12] invalid facility type [0] sequence number 0"
            @test_throws ArgumentError decode(SupplierCCN("12CXXXXXXX"))
        end
    end

    @testset "AbstractString interface" begin
        c = MedicareProviderCCN("12P456")

        @test ncodeunits(c) == 6
        @test codeunit(c) == UInt8
        @test codeunit(c, 1) == 0x31 # '1' in UTF-8
        @test iterate(c) == ('1', 2)
        @test iterate(c, 2) == ('2', 3)
        @test length(c) == 6  # BEWARE: only valid characters are counted!
        @test sizeof(c) == 6
        @test c * "ABC" == "12P456ABC"
        @test c^3 == "12P45612P45612P456"
        @test repeat(c, 3) == "12P45612P45612P456"
        @test String(c) == String("12P456")
        @test SubString(c, 4:5) == "45"
        @test c[4] == '4'
        @test codeunits(c) == codeunits("12P456")
        @test ascii(c) == "12P456"
        @test isless(c, "12P457") == true
        @test ==(c, "12P456")
        @test cmp(c, "12P455") == 1
        @test lpad(c, 10, 'x') == "xxxx12P456"
        @test rpad(c, 10, 'x') == "12P456xxxx"
        @test occursin(r"\D4\d", c) == true
        @test replace(c, r"\D4(\d)"=>s"hi\1") == "12hi56"
        @test startswith(c, "12") == true
        @test startswith(c, r"1\dp"i) == true
        @test endswith(c, "56") == true
        @test endswith(c, r"4\d6") == true
        @test contains(c, r"P..6") == true
        @test first(c, 2) == "12"
        @test last(c, 2) == "56"
        @test uppercase(c) == "12P456"
        @test lowercase(c) == "12p456"
        @test join([c, c], ",") == "12P456,12P456"
        @test chop(c) == "12P45"

        @test chomp(c) == c
        @test textwidth(c) == 6
        @test isascii(c) == true

        if VERSION >= v"1.8"
            @test collect(eachsplit(c, "P4")) == ["12", "56"]
            @test chopprefix(c, "12") == "P456"
            @test chopsuffix(c, "56") == "12P4"
        end
    end

    @testset "CSV" begin
        # The most common use case is reading CCNs from CSVs. CSV uses SentinelArrays, which
        # has some awkward behavior with InlineStrings (the default sentinel of a String7
        # appears to have length of 255).
        csv = b"""a
12345
123456
"""
        c = MedicareProviderCCN["012345", "123456"]
        f = CSV.File(csv; types=Dict(:a=>MedicareProviderCCN))
        @test f.a == c

        io = IOBuffer()
        CSV.write(io, f)
        # the writer corrects the string by left padding with zeros
        written_csv = b"""a
012345
123456
"""
        @test take!(io) == written_csv
    end
end