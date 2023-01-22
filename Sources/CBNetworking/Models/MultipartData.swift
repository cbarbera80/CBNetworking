import Foundation

public struct MultipartData {
    public let data: Data
    public let key: String
    public let fileName: String
    public let mimeType: String
    
    public init(data: Data, key: String, fileName: String, mimeType: String) {
        self.data = data
        self.key = key
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    internal func dataFormField(from multipartData: MultipartData) -> Data {
        let fieldData = NSMutableData()

        fieldData.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")

        return fieldData as Data
    }
}
