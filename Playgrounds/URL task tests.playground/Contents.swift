// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let rKICountyData = try RKICountyData(json)

import Foundation

// MARK: - RKICountyData
struct RKICountyData: Codable {
    var objectidFieldName: String
    var uniqueidField: UniqueidField
    var globalidFieldName: String
    var geometryProperties: GeometryProperties
    var geometryType: String
    var spatialReference: SpatialReference
    var fields: [Field]
    var features: [Feature]

    enum CodingKeys: String, CodingKey {
        case objectidFieldName = "objectIdFieldName"
        case uniqueidField = "uniqueIdField"
        case globalidFieldName = "globalIdFieldName"
        case geometryProperties = "geometryProperties"
        case geometryType = "geometryType"
        case spatialReference = "spatialReference"
        case fields = "fields"
        case features = "features"
    }
}

// MARK: RKICountyData convenience initializers and mutators

extension RKICountyData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RKICountyData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        objectidFieldName: String? = nil,
        uniqueidField: UniqueidField? = nil,
        globalidFieldName: String? = nil,
        geometryProperties: GeometryProperties? = nil,
        geometryType: String? = nil,
        spatialReference: SpatialReference? = nil,
        fields: [Field]? = nil,
        features: [Feature]? = nil
    ) -> RKICountyData {
        return RKICountyData(
            objectidFieldName: objectidFieldName ?? self.objectidFieldName,
            uniqueidField: uniqueidField ?? self.uniqueidField,
            globalidFieldName: globalidFieldName ?? self.globalidFieldName,
            geometryProperties: geometryProperties ?? self.geometryProperties,
            geometryType: geometryType ?? self.geometryType,
            spatialReference: spatialReference ?? self.spatialReference,
            fields: fields ?? self.fields,
            features: features ?? self.features
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Feature
struct Feature: Codable {
    var attributes: Attributes

    enum CodingKeys: String, CodingKey {
        case attributes = "attributes"
    }
}

// MARK: Feature convenience initializers and mutators

extension Feature {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Feature.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        attributes: Attributes? = nil
    ) -> Feature {
        return Feature(
            attributes: attributes ?? self.attributes
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Attributes
struct Attributes: Codable {
    var objectid: Int
    var ade: Int?
    var gf: Int?
    var bsg: Int?
    var rs: String
    var ags: String?
    var sdvRs: String?
    var gen: String
    var bez: Bez
    var ibz: Int?
    var bem: Bem?
    var nbd: Nbd?
    var snL: String?
    var snR: String?
    var snK: String?
    var snV1: String?
    var snV2: String?
    var snG: String?
    var fkS3: FkS3?
    var nuts: String?
    var rs0: String?
    var ags0: String?
    var wsk: String?
    var ewz: Int
    var kfl: Double?
    var debkgid: String?
    var shapeArea: Double
    var shapeLength: Double
    var deathRate: Double
    var cases: Int
    var deaths: Int
    var casesPer100K: Double
    var casesPerPopulation: Double
    var bl: Bl
    var blid: String
    var county: String
    var lastUpdate: LastUpdate
    var cases7Per100K: Double
    var recovered: JSONNull?
    var ewzBl: Int
    var cases7BlPer100K: Double

    enum CodingKeys: String, CodingKey {
        case objectid = "OBJECTID"
        case ade = "ADE"
        case gf = "GF"
        case bsg = "BSG"
        case rs = "RS"
        case ags = "AGS"
        case sdvRs = "SDV_RS"
        case gen = "GEN"
        case bez = "BEZ"
        case ibz = "IBZ"
        case bem = "BEM"
        case nbd = "NBD"
        case snL = "SN_L"
        case snR = "SN_R"
        case snK = "SN_K"
        case snV1 = "SN_V1"
        case snV2 = "SN_V2"
        case snG = "SN_G"
        case fkS3 = "FK_S3"
        case nuts = "NUTS"
        case rs0 = "RS_0"
        case ags0 = "AGS_0"
        case wsk = "WSK"
        case ewz = "EWZ"
        case kfl = "KFL"
        case debkgid = "DEBKG_ID"
        case shapeArea = "Shape__Area"
        case shapeLength = "Shape__Length"
        case deathRate = "death_rate"
        case cases = "cases"
        case deaths = "deaths"
        case casesPer100K = "cases_per_100k"
        case casesPerPopulation = "cases_per_population"
        case bl = "BL"
        case blid = "BL_ID"
        case county = "county"
        case lastUpdate = "last_update"
        case cases7Per100K = "cases7_per_100k"
        case recovered = "recovered"
        case ewzBl = "EWZ_BL"
        case cases7BlPer100K = "cases7_bl_per_100k"
    }
}

// MARK: Attributes convenience initializers and mutators

extension Attributes {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Attributes.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        objectid: Int? = nil,
        ade: Int?? = nil,
        gf: Int?? = nil,
        bsg: Int?? = nil,
        rs: String? = nil,
        ags: String?? = nil,
        sdvRs: String?? = nil,
        gen: String? = nil,
        bez: Bez? = nil,
        ibz: Int?? = nil,
        bem: Bem?? = nil,
        nbd: Nbd?? = nil,
        snL: String?? = nil,
        snR: String?? = nil,
        snK: String?? = nil,
        snV1: String?? = nil,
        snV2: String?? = nil,
        snG: String?? = nil,
        fkS3: FkS3?? = nil,
        nuts: String?? = nil,
        rs0: String?? = nil,
        ags0: String?? = nil,
        wsk: String?? = nil,
        ewz: Int? = nil,
        kfl: Double?? = nil,
        debkgid: String?? = nil,
        shapeArea: Double? = nil,
        shapeLength: Double? = nil,
        deathRate: Double? = nil,
        cases: Int? = nil,
        deaths: Int? = nil,
        casesPer100K: Double? = nil,
        casesPerPopulation: Double? = nil,
        bl: Bl? = nil,
        blid: String? = nil,
        county: String? = nil,
        lastUpdate: LastUpdate? = nil,
        cases7Per100K: Double? = nil,
        recovered: JSONNull?? = nil,
        ewzBl: Int? = nil,
        cases7BlPer100K: Double? = nil
    ) -> Attributes {
        return Attributes(
            objectid: objectid ?? self.objectid,
            ade: ade ?? self.ade,
            gf: gf ?? self.gf,
            bsg: bsg ?? self.bsg,
            rs: rs ?? self.rs,
            ags: ags ?? self.ags,
            sdvRs: sdvRs ?? self.sdvRs,
            gen: gen ?? self.gen,
            bez: bez ?? self.bez,
            ibz: ibz ?? self.ibz,
            bem: bem ?? self.bem,
            nbd: nbd ?? self.nbd,
            snL: snL ?? self.snL,
            snR: snR ?? self.snR,
            snK: snK ?? self.snK,
            snV1: snV1 ?? self.snV1,
            snV2: snV2 ?? self.snV2,
            snG: snG ?? self.snG,
            fkS3: fkS3 ?? self.fkS3,
            nuts: nuts ?? self.nuts,
            rs0: rs0 ?? self.rs0,
            ags0: ags0 ?? self.ags0,
            wsk: wsk ?? self.wsk,
            ewz: ewz ?? self.ewz,
            kfl: kfl ?? self.kfl,
            debkgid: debkgid ?? self.debkgid,
            shapeArea: shapeArea ?? self.shapeArea,
            shapeLength: shapeLength ?? self.shapeLength,
            deathRate: deathRate ?? self.deathRate,
            cases: cases ?? self.cases,
            deaths: deaths ?? self.deaths,
            casesPer100K: casesPer100K ?? self.casesPer100K,
            casesPerPopulation: casesPerPopulation ?? self.casesPerPopulation,
            bl: bl ?? self.bl,
            blid: blid ?? self.blid,
            county: county ?? self.county,
            lastUpdate: lastUpdate ?? self.lastUpdate,
            cases7Per100K: cases7Per100K ?? self.cases7Per100K,
            recovered: recovered ?? self.recovered,
            ewzBl: ewzBl ?? self.ewzBl,
            cases7BlPer100K: cases7BlPer100K ?? self.cases7BlPer100K
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum Bem: String, Codable {
    case empty = "--"
    case sonderverband = "Sonderverband"
}

enum Bez: String, Codable {
    case bezirk = "Bezirk"
    case kreis = "Kreis"
    case kreisfreieStadt = "Kreisfreie Stadt"
    case landkreis = "Landkreis"
    case stadtkreis = "Stadtkreis"
}

enum Bl: String, Codable {
    case badenWürttemberg = "Baden-Württemberg"
    case bayern = "Bayern"
    case berlin = "Berlin"
    case brandenburg = "Brandenburg"
    case bremen = "Bremen"
    case hamburg = "Hamburg"
    case hessen = "Hessen"
    case mecklenburgVorpommern = "Mecklenburg-Vorpommern"
    case niedersachsen = "Niedersachsen"
    case nordrheinWestfalen = "Nordrhein-Westfalen"
    case rheinlandPfalz = "Rheinland-Pfalz"
    case saarland = "Saarland"
    case sachsen = "Sachsen"
    case sachsenAnhalt = "Sachsen-Anhalt"
    case schleswigHolstein = "Schleswig-Holstein"
    case thüringen = "Thüringen"
}

enum FkS3: String, Codable {
    case k = "K"
    case r = "R"
}

enum LastUpdate: String, Codable {
    case the241120200000Uhr = "24.11.2020, 00:00 Uhr"
}

enum Nbd: String, Codable {
    case ja = "ja"
    case nein = "nein"
}

// MARK: - Field
struct Field: Codable {
    var name: String
    var type: TypeEnum
    var alias: String
    var sqlType: SQLType
    var domain: JSONNull?
    var defaultValue: JSONNull?
    var length: Int?

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case type = "type"
        case alias = "alias"
        case sqlType = "sqlType"
        case domain = "domain"
        case defaultValue = "defaultValue"
        case length = "length"
    }
}

// MARK: Field convenience initializers and mutators

extension Field {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Field.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        name: String? = nil,
        type: TypeEnum? = nil,
        alias: String? = nil,
        sqlType: SQLType? = nil,
        domain: JSONNull?? = nil,
        defaultValue: JSONNull?? = nil,
        length: Int?? = nil
    ) -> Field {
        return Field(
            name: name ?? self.name,
            type: type ?? self.type,
            alias: alias ?? self.alias,
            sqlType: sqlType ?? self.sqlType,
            domain: domain ?? self.domain,
            defaultValue: defaultValue ?? self.defaultValue,
            length: length ?? self.length
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum SQLType: String, Codable {
    case sqlTypeDouble = "sqlTypeDouble"
    case sqlTypeOther = "sqlTypeOther"
}

enum TypeEnum: String, Codable {
    case esriFieldTypeDouble = "esriFieldTypeDouble"
    case esriFieldTypeInteger = "esriFieldTypeInteger"
    case esriFieldTypeSmallInteger = "esriFieldTypeSmallInteger"
    case esriFieldTypeString = "esriFieldTypeString"
    case esriFieldTypeoid = "esriFieldTypeOID"
}

// MARK: - GeometryProperties
struct GeometryProperties: Codable {
    var shapeAreaFieldName: String
    var shapeLengthFieldName: String
    var units: String

    enum CodingKeys: String, CodingKey {
        case shapeAreaFieldName = "shapeAreaFieldName"
        case shapeLengthFieldName = "shapeLengthFieldName"
        case units = "units"
    }
}

// MARK: GeometryProperties convenience initializers and mutators

extension GeometryProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(GeometryProperties.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        shapeAreaFieldName: String? = nil,
        shapeLengthFieldName: String? = nil,
        units: String? = nil
    ) -> GeometryProperties {
        return GeometryProperties(
            shapeAreaFieldName: shapeAreaFieldName ?? self.shapeAreaFieldName,
            shapeLengthFieldName: shapeLengthFieldName ?? self.shapeLengthFieldName,
            units: units ?? self.units
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - SpatialReference
struct SpatialReference: Codable {
    var wkid: Int
    var latestWkid: Int

    enum CodingKeys: String, CodingKey {
        case wkid = "wkid"
        case latestWkid = "latestWkid"
    }
}

// MARK: SpatialReference convenience initializers and mutators

extension SpatialReference {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(SpatialReference.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        wkid: Int? = nil,
        latestWkid: Int? = nil
    ) -> SpatialReference {
        return SpatialReference(
            wkid: wkid ?? self.wkid,
            latestWkid: latestWkid ?? self.latestWkid
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - UniqueidField
struct UniqueidField: Codable {
    var name: String
    var isSystemMaintained: Bool

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case isSystemMaintained = "isSystemMaintained"
    }
}

// MARK: UniqueidField convenience initializers and mutators

extension UniqueidField {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(UniqueidField.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        name: String? = nil,
        isSystemMaintained: Bool? = nil
    ) -> UniqueidField {
        return UniqueidField(
            name: name ?? self.name,
            isSystemMaintained: isSystemMaintained ?? self.isSystemMaintained
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public func hash(into hasher: inout Hasher) {
        // No-op
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}


// MARK: -



enum RKI_DataTypeEnum {
    case county, state
}

struct RKI_DataTabStruct {
    let RKI_DataType: RKI_DataTypeEnum
    let URL_String: String
    
    init(_ dataType: RKI_DataTypeEnum, _ URLString: String) {
        self.RKI_DataType = dataType
        self.URL_String = URLString
    }
}

let RKI_DataTab: [RKI_DataTabStruct] = [
    
//    RKI_DataTabStruct(.county,  "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_Landkreisdaten/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&outSR=4326&f=json"),
    
    RKI_DataTabStruct(.state, "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/Coronaf%C3%A4lle_in_den_Bundesl%C3%A4ndern/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&outSR=4326&f=json")
]

func handleRKIContent( _ data: Data, _ RKI_DataType: RKI_DataTypeEnum) {

    print("receive 1:")
    do {

        print("receive 2:")

        let welcomeResult = try newJSONDecoder().decode(RKICountyData.self, from: data)

        print("receive 3:")

        switch RKI_DataType {
        case .county:
            print("County")
//            if welcomeResult.features != nil {
            for singleItem in welcomeResult.features {
                //if let test1 = singleItem.attributes!.bl {
                    print("\(singleItem.attributes.bl)")
                //}
            }
//            } else {
//                print("features == nil")
//            }
        case .state:
                print("State")
//            for singleItem in welcomeResult.features! {
//                print("\(String(describing: singleItem.attributes!.lanEwBEZ)), \(String(describing: singleItem.attributes!.objectid1)): \(String(describing: singleItem.attributes!.cases7BlPer100K))")
//            }

        }
        

    } catch let error as NSError {
        
        
        print("catch: error: \(error.description)")
    }
}

func getRKIData() {

    for singleDataSet in RKI_DataTab {
        let url = URL(string: singleDataSet.URL_String)!
        
        let task = URLSession.shared.dataTask(
            with: url,
            completionHandler: { data, response, error in
                
                // check if there are errors
                if error == nil {
                    
                    // no errors, go ahead
                    
                    // check if we have a valid HTTP response
                    if let httpResponse = response as? HTTPURLResponse {
                        
                        // check if we have a a good status (codes from 200 to 299 are always good
                        if (200...299).contains(httpResponse.statusCode) == true {
                            
                            // good status, go ahead
                            
                            // check if we have a mimeType
                            if let mimeType = httpResponse.mimeType {
                                
                                // check the mime type
                                if mimeType == "text/plain" {
                                    
                                    // right mime type, go ahead
                                    if data != nil {
                                        
                                        print("all good")
                                        
                                        // convert it to string and print it
                                        print("\(String(data: data!, encoding: .utf8) ?? "Convertion data to string failed")")
                                        
                                        // handle the content
                                        handleRKIContent(data!, singleDataSet.RKI_DataType)
                                    }
                                    
                                } else {
                                    
                                    // not the right mimeType, log message and return
                                    NSLog("CoBaT.RKIData.getRKICountyData: Error: URLSession.dataTask, wrong mimeType (\"\(mimeType)\" instead of \"text/plain\"), return")
                                    return
                                }
                                
                            } else {
                                
                                // no valid mimeType, log message and return
                                NSLog("CoBaT.RKIData.getRKICountyData: Error: URLSession.dataTask, no mimeType in response, return")
                                return
                            }
                            
                        } else {
                            
                            // not a good status, handle error and return
                            print("handleServerError()")
                            return
                        }
                        
                    } else {
                        
                        // no valid response, log message and return
                        NSLog("CoBaT.RKIData.getRKICountyData: Error: URLSession.dataTaskhas no valid HTTP response, return")
                        return
                    }
                    
                } else {
                    // error is not nil, checkc if error code is valid
                    if let myError = error {
                        
                        // valid errorCode, call the handler and return
                        print("handleServerError(), \(myError.localizedDescription)")
                        return
                        
                    } else {
                        
                        // no valid error code, log message and return
                        NSLog("CoBaT.RKIData.getRKICountyData: Error: URLSession.dataTask came back with error which is not nil, but no valid errorCode, return")
                        return
                    }
                }
            })
        
        // start the task
        task.resume()
    }
}




getRKIData()


