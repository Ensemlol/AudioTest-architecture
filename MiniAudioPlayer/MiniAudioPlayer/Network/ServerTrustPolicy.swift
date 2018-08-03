//
//  ServerTrustPolicy.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/8/3.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

/// Responsible for managing the mapping of `ServerTrustPolicy` objects to a given host.
open class ServerTrustPolicyManager {
    
    /// The dictionary of policies mapped to a particular host.
    open let policies: [String: ServerTrustPolicy]
    
    /// Initializes the `ServerTrustPolicyManager` instance with the given policies.
    /// - Discussion: Since different servers and web serivces can have different leaf certificates, intermediate and even root cerificates, it is important to have the flexibility to specify evaluation policies on a per host basis. This allows for secenarios such as using default evaluation for host1, certificate pinning for host2, public key pinning for host3 and disabling evaluation for host4.
    ///
    /// - Parameter policies: A dictionary of all policies mapped to a particular host.
    public init(policies: [String: ServerTrustPolicy]) {
        self.policies = policies
    }
    
    /// Returns the `ServerTrustPolicy` for the given host if applicable.
    ///
    /// - Discussion: By default, this method will return the policy that perfectly matches the given host. Subclasses could override this method and implement more complex mapping implementations such as wildcards.
    ///
    /// - Parameter host: The host to use when searching for a matching policy.
    ///
    /// - Returns: The server trust policy for the given host if found.
    func serverTrustPolicy(forHost host: String) -> ServerTrustPolicy? {
        return policies[host]
    }
}

//MARK: -

extension URLSession {
    private struct AssociateKeys {
        static var managerKey = "URLSession.ServerTrustPolicyManager"
    }
    
    var serverTrustPolicyManager: ServerTrustPolicyManager? {
        get {
            return objc_getAssociatedObject(self, &AssociateKeys.managerKey) as? ServerTrustPolicyManager
        }
        set (manager) {
            objc_setAssociatedObject(self, &AssociateKeys.managerKey, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public enum ServerTrustPolicy {
    case performDefaultEvaluation(validateHost: Bool)
    case performRevokedEvaluation(validateHost: Bool, revocationFlags: CFOptionFlags)
    case pinCertificates(certificates: [SecCertificate], validateCertufucateChain: Bool, validateHost: Bool)
    case pinPublicKeys(publicKeys: [SecKey], validateCertificateChain: Bool, validateHost: Bool)
    case disableEvaluation
    case customEvaluation((_ serverTrust: SecTrust, _ host: String) -> Bool)
    
    // MARK: - Bundle Location
    
    /// Returns all certificates within the given bundle with a `.cer` file extension.
    ///
    /// - Parameter bundle: The bundle to search for all `.cer` files.
    ///
    /// - Returns: All certificates within the given bundle.
    public static func certificates(in bundle: Bundle = Bundle.main) -> [SecCertificate] {
        var certificates: [SecCertificate] = []
        
        let paths = Set([".cer", ".CER", ".crt", ".CRT", ".der", ".DER"]).map { fileExtension in
            bundle.paths(forResourcesOfType: fileExtension, inDirectory: nil)
        }.joined()
        
        for path in paths {
            if let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData,
                let certificate = SecCertificateCreateWithData(nil, certificateData) {
                certificates.append(certificate)
            }
        }
        
        return certificates
    }
}
