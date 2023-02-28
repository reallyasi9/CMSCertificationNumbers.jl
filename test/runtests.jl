using CCNs
using Test

@testset "CCNs.jl" begin
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
            @test [isvalid(MedicareProviderCCN("1234567"), i) for i in 1:7] == fill(true, 7) # all characters are valid
            # Not enough characters
            @test !isvalid(MedicareProviderCCN("12345"))
            @test [isvalid(MedicareProviderCCN("12345"), i) for i in 1:5] == fill(true, 5) # all characters are valid
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
            @test state(MedicareProviderCCN("XX3456")) == CCNs.INVALID_STATE

            @test facility_type_code(MedicareProviderCCN("123456")) == "3400-3499"
            @test facility_type_code(MedicareProviderCCN("12P456")) == "P"
            @test_throws ArgumentError facility_type_code(MedicareProviderCCN("12X456"))
            @test facility_type(MedicareProviderCCN("123456")) == "Rural Health Clinic (Provider-based)"
            @test facility_type(MedicareProviderCCN("12P456")) == "Organ Procurement Organization (OPO)"
            @test facility_type(MedicareProviderCCN("12X456")) == CCNs.INVALID_FACILITY_TYPE

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
            @test [isvalid(MedicaidOnlyProviderCCN("12A4567"), i) for i in 1:7] == fill(true, 7) # all characters are valid
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
            @test state(MedicaidOnlyProviderCCN("XX3456")) == CCNs.INVALID_STATE

            @test facility_type_code(MedicaidOnlyProviderCCN("12A456")) == "A"
            @test facility_type(MedicaidOnlyProviderCCN("12A456")) == "NF (Formerly assigned to Medicaid SNF)"
            @test facility_type(MedicaidOnlyProviderCCN("12X456")) == CCNs.INVALID_FACILITY_TYPE

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
            @test [isvalid(IPPSExcludedProviderCCN("12M4567"), i) for i in 1:7] == fill(true, 7) # all characters are valid
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
            @test state(IPPSExcludedProviderCCN("XX3456")) == CCNs.INVALID_STATE

            @test facility_type_code(IPPSExcludedProviderCCN("12M456")) == "M"
            @test facility_type(IPPSExcludedProviderCCN("12M456")) == "Psychiatric Unit of a CAH"
            @test facility_type(IPPSExcludedProviderCCN("12X456")) == CCNs.INVALID_FACILITY_TYPE

            @test sequence_number(IPPSExcludedProviderCCN("12M456")) == 456
            @test_throws ArgumentError sequence_number(IPPSExcludedProviderCCN("12XXXX"))

            @test decode(IPPSExcludedProviderCCN("12M456")) == "12M456: IPPS-Excluded Provider in Hawaii [12] Psychiatric Unit of a CAH [M] of parent with sequence number 456"
            @test decode(IPPSExcludedProviderCCN("XXM456")) == "XXM456: IPPS-Excluded Provider in invalid state [XX] Psychiatric Unit of a CAH [M] of parent with sequence number 456"
            @test decode(IPPSExcludedProviderCCN("120000")) == "120000: IPPS-Excluded Provider in Hawaii [12] invalid facility type [0] of parent with sequence number 0"
            @test decode(IPPSExcludedProviderCCN("12MA56")) == "12MA56: IPPS-Excluded Provider in Hawaii [12] Psychiatric Unit of a CAH [M] of parent LTCH [A] with sequence number 2056"
            @test_throws ArgumentError decode(IPPSExcludedProviderCCN("12MXXX"))
        end
    end

    @testset "AbstractString interface" begin
        c = MedicareProviderCCN("12P456")

        @test ncodeunits(c) == 6
        @test codeunit(c) == UInt8
        @test codeunit(c, 1) == 0x31 # '1' in UTF-8
        @test iterate(c) == ('1', 2)
        @test iterate(c, 2) == ('2', 3)
        @test transcode(UInt16, c) == UInt16[0x0031, 0x0032, 0x0050, 0x0034, 0x0035, 0x0036] # "12P456" in UTF-16
        @test reverse(c) == "654P21"

        # surprisingly, everything else in the AbstractString interface follows from those definitions
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
        @test findfirst('4', c) == 4
        @test findnext('4', c, 5) === nothing
        @test findlast(<('5'), c) == 4
        @test findprev("2P", c, 5) == 2:3
        @test occursin(r"\D4\d", c) == true
        @test replace(c, r"\D4(\d)"=>s"hi\1") == "12hi56"
        @test collect(eachsplit(c, "P4")) == ["12", "56"]
        @test split(c, "P4") == ["12", "56"]
        @test rsplit(c, "4", limit=2, keepempty=true) == ["12P", "56"]
        @test strip(c, ['1', '6']) == "2P45"
        @test lstrip(c, ['1', '6']) == "2P456"
        @test rstrip(c, ['1', '6']) == "12P45"
        @test startswith(c, "12") == true
        @test startswith(c, r"1\dp"i) == true
        @test endswith(c, "56") == true
        @test endswith(c, r"4\d6") == true
        @test contains(c, r"P..6") == true
        @test first(c, 2) == "12"
        @test last(c, 2) == "56"
        @test uppercase(c) == "12P456"
        @test lowercase(c) == "12p456"
        @test uppercasefirst(c) == titlecase(c) == "12P456"
        @test lowercasefirst(c) == c
        @test join([c, c], ",") == "12P456,12P456"
        @test chop(c) == "12P45"
        @test chopprefix(c, "12") == "P456"
        @test chopsuffix(c, "56") == "12P4"
        @test chomp(c) == c
        @test thisind(c, 3) == 3
        @test nextind(c, 3) == 4
        @test prevind(c, 3) == 2
        @test textwidth(c) == 6
        @test isascii(c) == true
        @test escape_string(c) == c
        @test unescape_string(c) == c
    end
end