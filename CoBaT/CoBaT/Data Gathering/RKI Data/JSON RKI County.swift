//
//  JSON RKI County.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 24.11.20.
//

// file generated by website "https://app.quicktype.io" which creates
// full JSON decode data structures and helper methodes out of JSON example data
// very usefull!!

// created file has been adjusted for internal use

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let rKICountyJSON = try RKI_County_JSON(json)

import Foundation

// MARK: - RKI_County_JSON
struct RKI_County_JSON: Codable {
    var objectidFieldName: String
    var uniqueidField: RKI_County_UniqueidField
    var globalidFieldName: String
    var geometryProperties: RKI_County_GeometryProperties
    var geometryType: String
    var spatialReference: RKI_County_SpatialReference
    var fields: [RKI_County_Field]
    var features: [RKI_County_Feature]

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

// MARK: RKI_County_JSON convenience initializers and mutators

fileprivate extension RKI_County_JSON {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RKI_County_JSON.self, from: data)
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
        uniqueidField: RKI_County_UniqueidField? = nil,
        globalidFieldName: String? = nil,
        geometryProperties: RKI_County_GeometryProperties? = nil,
        geometryType: String? = nil,
        spatialReference: RKI_County_SpatialReference? = nil,
        fields: [RKI_County_Field]? = nil,
        features: [RKI_County_Feature]? = nil
    ) -> RKI_County_JSON {
        return RKI_County_JSON(
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

// MARK: - RKI_County_Feature
struct RKI_County_Feature: Codable {
    var attributes: RKI_County_Attributes

    enum CodingKeys: String, CodingKey {
        case attributes = "attributes"
    }
}

// MARK: RKI_County_Feature convenience initializers and mutators

fileprivate extension RKI_County_Feature {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RKI_County_Feature.self, from: data)
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
        attributes: RKI_County_Attributes? = nil
    ) -> RKI_County_Feature {
        return RKI_County_Feature(
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

// MARK: - RKI_County_Attributes
struct RKI_County_Attributes: Codable {
    var objectid: Int
    var ade: Int?
    var gf: Int?
    var bsg: Int?
    var rs: String
    var ags: String?
    var sdvRs: String?
    var gen: String
    var bez: RKI_County_Bez
    var ibz: Int?
    var bem: RKI_County_Bem?
    var nbd: RKI_County_Nbd?
    var snL: String?
    var snR: String?
    var snK: String?
    var snV1: String?
    var snV2: String?
    var snG: String?
    var fkS3: RKI_County_FkS3?
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
    var bl: RKI_County_Bl
    var blid: String
    var county: String
    var lastUpdate: String
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

// MARK: RKI_County_Attributes convenience initializers and mutators

fileprivate extension RKI_County_Attributes {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RKI_County_Attributes.self, from: data)
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
        bez: RKI_County_Bez? = nil,
        ibz: Int?? = nil,
        bem: RKI_County_Bem?? = nil,
        nbd: RKI_County_Nbd?? = nil,
        snL: String?? = nil,
        snR: String?? = nil,
        snK: String?? = nil,
        snV1: String?? = nil,
        snV2: String?? = nil,
        snG: String?? = nil,
        fkS3: RKI_County_FkS3?? = nil,
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
        bl: RKI_County_Bl? = nil,
        blid: String? = nil,
        county: String? = nil,
        //lastUpdate: RKI_County_LastUpdate? = nil,
        lastUpdate: String? = nil,
        cases7Per100K: Double? = nil,
        recovered: JSONNull?? = nil,
        ewzBl: Int? = nil,
        cases7BlPer100K: Double? = nil
    ) -> RKI_County_Attributes {
        return RKI_County_Attributes(
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

enum RKI_County_Bem: String, Codable {
    case empty = "--"
    case sonderverband = "Sonderverband"
}

enum RKI_County_Bez: String, Codable {
    case bezirk = "Bezirk"
    case kreis = "Kreis"
    case kreisfreieStadt = "Kreisfreie Stadt"
    case landkreis = "Landkreis"
    case stadtkreis = "Stadtkreis"
}

enum RKI_County_Bl: String, Codable {
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

enum RKI_County_FkS3: String, Codable {
    case k = "K"
    case r = "R"
}

/*
enum RKI_County_LastUpdate: String, Codable {
    case the241120200000Uhr = "24.11.2020, 00:00 Uhr"
}
*/

enum RKI_County_Nbd: String, Codable {
    case ja = "ja"
    case nein = "nein"
}

// MARK: - RKI_County_Field
struct RKI_County_Field: Codable {
    var name: String
    var type: RKI_County_Type
    var alias: String
    var sqlType: RKI_County_SQLType
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

// MARK: RKI_County_Field convenience initializers and mutators

fileprivate extension RKI_County_Field {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RKI_County_Field.self, from: data)
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
        type: RKI_County_Type? = nil,
        alias: String? = nil,
        sqlType: RKI_County_SQLType? = nil,
        domain: JSONNull?? = nil,
        defaultValue: JSONNull?? = nil,
        length: Int?? = nil
    ) -> RKI_County_Field {
        return RKI_County_Field(
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

enum RKI_County_SQLType: String, Codable {
    case sqlTypeDouble = "sqlTypeDouble"
    case sqlTypeInteger = "sqlTypeInteger"
    case sqlTypeOther = "sqlTypeOther"
}

enum RKI_County_Type: String, Codable {
    case esriFieldTypeDouble = "esriFieldTypeDouble"
    case esriFieldTypeInteger = "esriFieldTypeInteger"
    case esriFieldTypeSmallInteger = "esriFieldTypeSmallInteger"
    case esriFieldTypeString = "esriFieldTypeString"
    case esriFieldTypeoid = "esriFieldTypeOID"
}

// MARK: - RKI_County_GeometryProperties
struct RKI_County_GeometryProperties: Codable {
    var shapeAreaFieldName: String
    var shapeLengthFieldName: String
    var units: String

    enum CodingKeys: String, CodingKey {
        case shapeAreaFieldName = "shapeAreaFieldName"
        case shapeLengthFieldName = "shapeLengthFieldName"
        case units = "units"
    }
}

// MARK: RKI_County_GeometryProperties convenience initializers and mutators

fileprivate extension RKI_County_GeometryProperties {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RKI_County_GeometryProperties.self, from: data)
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
    ) -> RKI_County_GeometryProperties {
        return RKI_County_GeometryProperties(
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

// MARK: - RKI_County_SpatialReference
struct RKI_County_SpatialReference: Codable {
    var wkid: Int
    var latestWkid: Int

    enum CodingKeys: String, CodingKey {
        case wkid = "wkid"
        case latestWkid = "latestWkid"
    }
}

// MARK: RKI_County_SpatialReference convenience initializers and mutators

fileprivate extension RKI_County_SpatialReference {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RKI_County_SpatialReference.self, from: data)
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
    ) -> RKI_County_SpatialReference {
        return RKI_County_SpatialReference(
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

// MARK: - RKI_County_UniqueidField
struct RKI_County_UniqueidField: Codable {
    var name: String
    var isSystemMaintained: Bool

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case isSystemMaintained = "isSystemMaintained"
    }
}

// MARK: RKI_County_UniqueidField convenience initializers and mutators

fileprivate extension RKI_County_UniqueidField {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RKI_County_UniqueidField.self, from: data)
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
    ) -> RKI_County_UniqueidField {
        return RKI_County_UniqueidField(
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
