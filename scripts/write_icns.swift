import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: write_icns.swift <iconset-dir> <output.icns>\n", stderr)
    exit(64)
}

let iconsetURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

let entries: [(type: String, file: String)] = [
    ("icp4", "icon_16x16.png"),
    ("icp5", "icon_32x32.png"),
    ("icp6", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic08", "icon_256x256.png"),
    ("ic09", "icon_512x512.png"),
    ("ic10", "icon_512x512@2x.png"),
]

func appendFourCC(_ fourCC: String, to data: inout Data) {
    precondition(fourCC.utf8.count == 4)
    data.append(contentsOf: fourCC.utf8)
}

func appendUInt32BE(_ value: UInt32, to data: inout Data) {
    data.append(UInt8((value >> 24) & 0xff))
    data.append(UInt8((value >> 16) & 0xff))
    data.append(UInt8((value >> 8) & 0xff))
    data.append(UInt8(value & 0xff))
}

var chunks = Data()

for entry in entries {
    let pngURL = iconsetURL.appendingPathComponent(entry.file)
    let pngData = try Data(contentsOf: pngURL)
    let chunkLength = UInt32(pngData.count + 8)

    appendFourCC(entry.type, to: &chunks)
    appendUInt32BE(chunkLength, to: &chunks)
    chunks.append(pngData)
}

var output = Data()
appendFourCC("icns", to: &output)
appendUInt32BE(UInt32(chunks.count + 8), to: &output)
output.append(chunks)

try output.write(to: outputURL, options: .atomic)
