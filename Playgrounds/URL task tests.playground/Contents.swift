// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try Welcome(json)

import Foundation

// MARK: - RKI_County_Data
struct RKI_County_Data: Codable {
    var objectIDFieldName: String
    var uniqueIDField: UniqueIDField
    var globalIDFieldName, geometryType: String
    var spatialReference: SpatialReference
    var fields: [Field]
    var features: [Feature]

    enum CodingKeys: String, CodingKey {
        case objectIDFieldName = "objectIdFieldName"
        case uniqueIDField = "uniqueIdField"
        case globalIDFieldName = "globalIdFieldName"
        case geometryType, spatialReference, fields, features
    }
}

// MARK: RKI_County_Data convenience initializers and mutators

extension RKI_County_Data {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RKI_County_Data.self, from: data)
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
        objectIDFieldName: String? = nil,
        uniqueIDField: UniqueIDField? = nil,
        globalIDFieldName: String? = nil,
        geometryType: String? = nil,
        spatialReference: SpatialReference? = nil,
        fields: [Field]? = nil,
        features: [Feature]? = nil
    ) -> RKI_County_Data {
        return RKI_County_Data(
            objectIDFieldName: objectIDFieldName ?? self.objectIDFieldName,
            uniqueIDField: uniqueIDField ?? self.uniqueIDField,
            globalIDFieldName: globalIDFieldName ?? self.globalIDFieldName,
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
    var gen: String
    var bez: Bez
    var deathRate: Double
    var cases, deaths: Int
    var casesPer100K, casesPerPopulation: Double
    var bl: Bl
    var blID, county: String
    var lastUpdate: LastUpdate
    var cases7Per100K: Double
    var recovered: JSONNull?
    var ewzBl: Int
    var cases7BlPer100K: Double

    enum CodingKeys: String, CodingKey {
        case gen = "GEN"
        case bez = "BEZ"
        case deathRate = "death_rate"
        case cases, deaths
        case casesPer100K = "cases_per_100k"
        case casesPerPopulation = "cases_per_population"
        case bl = "BL"
        case blID = "BL_ID"
        case county
        case lastUpdate = "last_update"
        case cases7Per100K = "cases7_per_100k"
        case recovered
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
        gen: String? = nil,
        bez: Bez? = nil,
        deathRate: Double? = nil,
        cases: Int? = nil,
        deaths: Int? = nil,
        casesPer100K: Double? = nil,
        casesPerPopulation: Double? = nil,
        bl: Bl? = nil,
        blID: String? = nil,
        county: String? = nil,
        lastUpdate: LastUpdate? = nil,
        cases7Per100K: Double? = nil,
        recovered: JSONNull?? = nil,
        ewzBl: Int? = nil,
        cases7BlPer100K: Double? = nil
    ) -> Attributes {
        return Attributes(
            gen: gen ?? self.gen,
            bez: bez ?? self.bez,
            deathRate: deathRate ?? self.deathRate,
            cases: cases ?? self.cases,
            deaths: deaths ?? self.deaths,
            casesPer100K: casesPer100K ?? self.casesPer100K,
            casesPerPopulation: casesPerPopulation ?? self.casesPerPopulation,
            bl: bl ?? self.bl,
            blID: blID ?? self.blID,
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

enum LastUpdate: String, Codable {
    case the221120200000Uhr = "22.11.2020, 00:00 Uhr"
}

// MARK: - Field
struct Field: Codable {
    var name: String
    var type: TypeEnum
    var alias: String
    var sqlType: SQLType
    var length: Int?
    var domain, defaultValue: JSONNull?
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
        length: Int?? = nil,
        domain: JSONNull?? = nil,
        defaultValue: JSONNull?? = nil
    ) -> Field {
        return Field(
            name: name ?? self.name,
            type: type ?? self.type,
            alias: alias ?? self.alias,
            sqlType: sqlType ?? self.sqlType,
            length: length ?? self.length,
            domain: domain ?? self.domain,
            defaultValue: defaultValue ?? self.defaultValue
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
    case sqlTypeOther = "sqlTypeOther"
}

enum TypeEnum: String, Codable {
    case esriFieldTypeDouble = "esriFieldTypeDouble"
    case esriFieldTypeInteger = "esriFieldTypeInteger"
    case esriFieldTypeString = "esriFieldTypeString"
}

// MARK: - SpatialReference
struct SpatialReference: Codable {
    var wkid, latestWkid: Int
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

// MARK: - UniqueIDField
struct UniqueIDField: Codable {
    var name: String
    var isSystemMaintained: Bool
}

// MARK: UniqueIDField convenience initializers and mutators

extension UniqueIDField {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(UniqueIDField.self, from: data)
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
    ) -> UniqueIDField {
        return UniqueIDField(
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

func getRKICountyData() {
    let url = URL(string:
                    "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_Landkreisdaten/FeatureServer/0/query?where=1%3D1&outFields=GEN,BEZ,death_rate,cases,deaths,cases_per_100k,cases_per_population,BL,BL_ID,county,last_update,cases7_per_100k,recovered,EWZ_BL,cases7_bl_per_100k&returnGeometry=false&outSR=4326&f=json")!
    

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            handleClientError(error)
            return
        }
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
       
        
        else {
            handleServerError(response)
            return
        }
        
        print("status: \(httpResponse.statusCode)")
        print ("mimeType: \(String(describing: httpResponse.mimeType))")
        
        
        if let mimeType = httpResponse.mimeType,
           mimeType == "text/plain",
            let data = data
            //let stringData = String(data: data, encoding: .utf8)
        {
            print("receive:")
            handleContent(data)
            
        } else {
            print("nothing")
        }
        
        
    }
    
    task.resume()
}

func handleServerError(_ response: URLResponse?) {
    
    print("handleServerError()")
    
}

func handleClientError(_ error: Error?) {
    
    print("handleServerError()")
    
}

func handleContent( _ data: Data) {
    
    print("receive 1:")
    do {
 
        print("receive 2:")

        let welcomeResult = try newJSONDecoder().decode(RKI_County_Data.self, from: data)
            
        print("receive 3:")
        
        for singleItem in welcomeResult.features {
            print("\(singleItem.attributes.bl), \(singleItem.attributes.gen): \(singleItem.attributes.cases7Per100K)")
        }

    } catch {
        print("catch: error")
    }
}

getRKICountyData()


