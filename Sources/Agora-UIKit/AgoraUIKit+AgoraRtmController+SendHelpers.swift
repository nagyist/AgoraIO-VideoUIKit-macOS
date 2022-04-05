//
//  AgoraUIKit+AgoraRtmController+Extensions.swift
//  
//
//  Created by Max Cobb on 04/04/2022.
//

import Foundation
#if canImport(AgoraRtmController)
import AgoraRtmKit
import AgoraRtmController
#endif

extension AgoraVideoViewer {
    /// Type of decoded message coming from other users
    public enum DecodedRtmAction {
        /// Mute is when a user is requesting another user to mute or unmute a device
        case mute(_: MuteRequest)
        /// DecodedRtmAction type containing data about a user (local or remote)
        case userData(_: AgoraVideoViewer.UserData)
        /// Message that contains a small action request, such as a ping or requesting a user's data
        case dataRequest(_: RtmDataRequest)
    }

    /// Decode message to a compatible DecodedRtmMessage type.
    /// - Parameters:
    ///   - data: Raw data input, should be utf8 encoded JSON string of MuteRequest or UserData.
    ///   - rtmId: Sender Real-time Messaging ID.
    /// - Returns: DecodedRtmMessage enum of the appropriate type.
    internal static func decodeRawRtmData(data: Data, from rtmId: String) -> DecodedRtmAction? {
        let decoder = JSONDecoder()
        if let userData = try? decoder.decode(AgoraVideoViewer.UserData.self, from: data) {
            return .userData(userData)
        } else if let muteReq = try? decoder.decode(MuteRequest.self, from: data) {
            return .mute(muteReq)
        } else if let requestVal = try? decoder.decode(RtmDataRequest.self, from: data) {
            return .dataRequest(requestVal)
        }
        return nil
    }

    #if canImport(AgoraRtmController)
    /// Share local UserData to all connected channels.
    /// Call this method when personal details are updated.
    open func broadcastPersonalData() {
        for channel in (self.rtmController?.channels ?? [String: AgoraRtmChannel]()) {
            self.sendPersonalData(to: channel.value)
        }
    }

    /// Share local UserData to a specific channel
    /// - Parameter channel: Channel to share UserData with.
    open func sendPersonalData(to channel: AgoraRtmChannel) {
        self.rtmController?.sendRaw(message: self.personalData(), channel: channel) { sendMsgState in
            switch sendMsgState {
            case .errorOk:
                AgoraVideoViewer.agoraPrint(
                    .verbose, message: "Personal data sent to channel successfully"
                )
            case .errorFailure, .errorTimeout, .tooOften,
                 .invalidMessage, .errorNotInitialized, .notLoggedIn:
                AgoraVideoViewer.agoraPrint(
                    .error, message: "Could not send message to channel \(sendMsgState.rawValue)"
                )
            @unknown default:
                AgoraVideoViewer.agoraPrint(.error, message: "Could not send message to channel (unknown)")
            }
        }
        AgoraVideoViewer.agoraPrint(.warning, message: "AgoraRtmController not included, override this method to send personal data")
    }

    /// Share local UserData to a specific RTM member
    /// - Parameter member: Member to share UserData with.
    open func sendPersonalData(to member: String) {
        self.rtmController?.sendRaw(message: self.personalData(), member: member) { sendMsgState in
            switch sendMsgState {
            case .ok:
                AgoraVideoViewer.agoraPrint(
                    .verbose, message: "Personal data sent to member successfully"
                )
            case .failure, .timeout, .tooOften, .invalidMessage, .notInitialized, .notLoggedIn,
                 .peerUnreachable, .cachedByServer, .invalidUserId, .imcompatibleMessage:
                AgoraVideoViewer.agoraPrint(
                    .error, message: "Could not send message to channel \(sendMsgState.rawValue)"
                )
            @unknown default:
                AgoraVideoViewer.agoraPrint(.error, message: "Could not send message to channel (unknown)")
            }
        }
    }
    #endif
}
