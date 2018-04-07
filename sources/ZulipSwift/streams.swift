import Foundation
import Alamofire

/*:
    An error that occurs during stream operations, before an HTTP request is
    made.
 */
public enum StreamError: Error {
    //: An error that occurs when a list of Zulip streams is invalid.
    case invalidStreams

    //: An error that occurs when a list of Zulip principals is invalid.
    case invalidPrincipals
}

//: A client for interacting with Zulip's messaging functionality.
public class Streams {
    private var config: Config

    /*:
        Initializes a `Streams` client.

         - Parameters:
            - config: The `Config` to use.
     */
    init(config: Config) {
        self.config = config
    }

    /*:
        Gets all streams that a user can access.

         - Parameters:
            - includePublic: Whether all public streams should be included.
            - includeSubscribed: Whether all subscribed-to streams should be
              included
            - includeDefault: Whether all default streams should be included.
            - includeActive: Whether all active streams should be included.
              This option will cause a `ZulipError` if the user not an admin.
            - callback: A callback, which will be passed the streams, or an
              error.
     */
    func getAll(
        includePublic: Bool = true,
        includeSubscribed: Bool = true,
        includeDefault: Bool = false,
        includeAllActive: Bool = false,
        callback: @escaping (
            Array<Dictionary<String, Any>>?,
            Error?
        ) -> Void
    ) {
        let params = [
            "include_public": includePublic ? "true" : "false",
            "include_subscribed": includeSubscribed ? "true" : "false",
            "include_default": includeDefault ? "true" : "false",
            "include_all_active": includeAllActive ? "true" : "false",
        ]

        makeGetRequest(
            url: self.config.apiURL + "/streams",
            params: params,
            username: config.emailAddress,
            password: config.apiKey,
            callback: { (response) in
                guard
                    let streams = getChildFromJSONResponse(
                        response: response,
                        childKey: "streams"
                    ) as? Array<Dictionary<String, Any>>
                else {
                    callback(
                        nil,
                        getZulipErrorFromResponse(response: response)
                    )
                    return
                }

                callback(streams, nil)
            }
        )
    }

    /*:
        Gets the ID of a stream.

         - Parameters:
            - name: The name of the stream.
            - callback: A callback, which will be passed the ID, or an error.
     */
    func getID(
        name: String,
        callback: @escaping (Int?, Error?) -> Void
    ) {
        let params = [
            "stream": name,
        ]

        makeGetRequest(
            url: self.config.apiURL + "/get_stream_id",
            params: params,
            username: config.emailAddress,
            password: config.apiKey,
            callback: { (response) in
                guard
                    let id = getChildFromJSONResponse(
                        response: response,
                        childKey: "stream_id"
                    ) as? Int
                else {
                    callback(
                        nil,
                        getZulipErrorFromResponse(response: response)
                    )
                    return
                }

                callback(id, nil)
            }
        )
    }

    /*:
        Gets the user's subscribed streams.

         - Parameters:
            - callback: A callback, which will be passed the streams, or an
              error.
     */
    func getSubscribed(
        callback: @escaping (
            Array<Dictionary<String, Any>>?,
            Error?
        ) -> Void
    ) {
        makeGetRequest(
            url: self.config.apiURL + "/users/me/subscriptions",
            params: [:],
            username: config.emailAddress,
            password: config.apiKey,
            callback: { (response) in
                guard
                    let streams = getChildFromJSONResponse(
                        response: response,
                        childKey: "subscriptions"
                    ) as? Array<Dictionary<String, Any>>
                else {
                    callback(
                        nil,
                        getZulipErrorFromResponse(response: response)
                    )
                    return
                }

                callback(streams, nil)
            }
        )
    }

    /*:
        Subscribes a user to streams, or creates them if they do not exist yet.

         - Parameters:
            - streams: The streams to subscribe a user to.
               - Example: `[["name": "test here"]]`
               - Example: `["name": "test here"], ["name": "announce"]]`
            - inviteOnly: Whether the streams are invite only or not.
            - announce: Whether an announcement should be made that a new
              stream is created if it is.
            - principals: The users to subscribe to the streams. If
              `principals` is empty, the current user will be subscribed.
            - authorizationErrorsFatal: Whether authorization errors should be
              reported in the response.
            - callback: A callback, which will be passed a dictionary where the
              key is user's email, and the value is a list of streams they were
              subscribed to; a dictionary where the key is a user's email, and
              the value is a list of streams they are already subscribed to;
              and a list of names of streams that could not be subscribed to
              because the user was unauthorized; or an error if there is one.
     */
    func subscribe(
        streams: Array<Dictionary<String, Any>>,
        inviteOnly: Bool = false,
        announce: Bool = false,
        principals: [String] = [],
        authorizationErrorsFatal: Bool = true,
        callback: @escaping (
            Dictionary<String, Array<String>>?,
            Dictionary<String, Array<String>>?,
            Array<String>?,
            Error?
        ) -> Void
    ) {
        guard
            let streamsData = try? JSONSerialization.data(
                withJSONObject: streams
            ),
            let streamsString = String(
                data: streamsData,
                encoding: String.Encoding.utf8
            )
        else {
            callback(nil, nil, nil, StreamError.invalidStreams)
            return
        }

        guard
            let principalsData = try? JSONSerialization.data(
                withJSONObject: principals
            ),
            let principalsString = String(
                data: principalsData,
                encoding: String.Encoding.utf8
            )
        else {
            callback(nil, nil, nil, StreamError.invalidPrincipals)
            return
        }

        let params = [
            "subscriptions": streamsString,
            "invite_only": inviteOnly ? "true" : "false",
            "announce": announce ? "true" : "false",
            "principals": principalsString,
            "authorization_errors_fatal":
                authorizationErrorsFatal ? "true" : "false",
        ]

        makePostRequest(
            url: self.config.apiURL + "/users/me/subscriptions",
            params: params,
            username: config.emailAddress,
            password: config.apiKey,
            callback: { (response) in
                if let errorMessage = getChildFromJSONResponse(
                    response: response,
                    childKey: "msg"
                ) as? String, errorMessage != "" {
                    callback(
                        nil,
                        nil,
                        nil,
                        ZulipError.error(message: errorMessage)
                    )
                    return
                }

                let subscribed = getChildFromJSONResponse(
                    response: response,
                    childKey: "subscribed"
                ) as? Dictionary<String, Array<String>>
                let alreadySubscribed = getChildFromJSONResponse(
                    response: response,
                    childKey: "already_subscribed"
                ) as? Dictionary<String, Array<String>>
                let unauthorized = getChildFromJSONResponse(
                    response: response,
                    childKey: "unauthorized"
                ) as? Array<String>

                callback(subscribed, alreadySubscribed, unauthorized, nil)
            }
        )
    }
}
