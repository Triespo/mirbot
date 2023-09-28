//
//  AboutViewController.swift
//  mirbot
//
//  Created by Miguel Ángel Jareño Escudero on 09/10/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//
// It shows all the organizations that the application have been supported
//

class AboutViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        }
        else {
            return .portrait
        }
    }
    
    func dismiss(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func showAlert(_ message: String) {
        AlertControllerSingleButton.showAlert("License", withMessage: message, withButtonTitle: "OK", in: self)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if section == 0 {
            return 3
        }
        else if section == 1 {
            return 6
        }
        else if section == 2 {
            return 3
        }
        else if section == 3 {
            return 4
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "People"
        case 1:
            return "Supported by"
        case 2:
            return "Feedback"
        case 3:
            return "Third party acknowledgments"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier = "Cell"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }
        var imageName = ""
        switch indexPath.section {
        case 0:
            cell?.selectionStyle = .none
            cell?.imageView?.image = nil
            cell?.accessoryType = .none
            if indexPath.row == 0 {
                cell?.textLabel?.text = "Antonio Pertusa"
                cell?.detailTextLabel?.text = "Project coordination & iOS development"
            }
            else if indexPath.row == 1 {
                cell?.textLabel?.text = "Javier Gallego"
                cell?.detailTextLabel?.text = "Server management"
            }
            else if indexPath.row == 2 {
                cell?.textLabel?.text = "Miguel Ángel Jareño"
                cell?.detailTextLabel?.text = "Swift 4 developer"
            }
            
        case 1:
            cell?.selectionStyle = .blue
            cell?.accessoryType = .none
            cell?.detailTextLabel?.numberOfLines = 2
            if indexPath.row == 0 {
                cell?.textLabel?.text = "GRFIA"
                cell?.detailTextLabel?.text = "Pattern Recognition and Artificial Intelligence Group"
                imageName = "praig.png"
            }
            else if indexPath.row == 1 {
                cell?.detailTextLabel?.text = nil
                cell?.textLabel?.text = cell?.detailTextLabel?.text
                imageName = "dlsi.png"
            }
            else if indexPath.row == 2 {
                cell?.textLabel?.text = "UA"
                cell?.detailTextLabel?.text = "University of Alicante"
                imageName = "logoua_short.png"
            }
            else if indexPath.row == 3 {
                cell?.textLabel?.text = nil
                cell?.detailTextLabel?.text = cell?.textLabel?.text
                imageName = "MIPRCV.png"
            }
            else if indexPath.row == 4 {
                cell?.textLabel?.text = nil
                cell?.detailTextLabel?.text = cell?.textLabel?.text
                imageName = "pascal2.png"
            }
            else if indexPath.row == 5 {
                cell?.textLabel?.text = nil
                cell?.detailTextLabel?.text = cell?.textLabel?.text
                imageName = "IUII.png"
            }
            
            cell?.imageView?.image = UIImage(named: imageName)
        case 2:
            cell?.selectionStyle = .blue
            cell?.accessoryType = .disclosureIndicator
            cell?.detailTextLabel?.text = nil
            cell?.imageView?.image = nil
            if indexPath.row == 0 {
                cell?.textLabel?.text = "Project webpage"
            }
            else if indexPath.row == 1 {
                cell?.textLabel?.text = "Contact us"
            }
            else if indexPath.row == 2 {
                cell?.textLabel?.text = "Rate this app"
            }
            
        case 3:
            cell?.imageView?.image = nil
            if indexPath.row == 0 {
                cell?.selectionStyle = .blue
                cell?.accessoryType = .disclosureIndicator
                cell?.textLabel?.text = "Wordnet 3.0"
                cell?.detailTextLabel?.text = "Princeton University"
                // http://wordnet.princeton.edu/wordnet/license/
            }
            else if indexPath.row == 1 {
                cell?.selectionStyle = .blue
                cell?.accessoryType = .disclosureIndicator
                cell?.textLabel?.text = "FGallery"
                cell?.detailTextLabel?.text = "Grant Davis"
                //http://cocoacontrols.com/platforms/ios/controls/fgallery
            }
            else if indexPath.row == 2 {
                cell?.selectionStyle = .none
                cell?.accessoryType = .none
                cell?.textLabel?.text = "Robot renders"
                cell?.detailTextLabel?.text = "AO Maru created by Leo Blanchette"
            }
            else if indexPath.row == 3 {
                cell?.selectionStyle = .blue
                cell?.accessoryType = .disclosureIndicator
                cell?.textLabel?.text = "UUIDHandler"
                cell?.detailTextLabel?.text = "Doug Russell"
            }
            
        default:
            break
        }
        return cell!
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            var URL: String? = nil
            switch indexPath.row {
            case 0:
                URL = "http://grfia.dlsi.ua.es"
            case 1:
                URL = "http://www.dlsi.ua.es/?id=eng"
            case 2:
                URL = "http://www.ua.es/en/"
            case 3:
                URL = "http://miprcv.iti.upv.es/"
            case 4:
                URL = "http://www.pascal-network.org/"
            case 5:
                URL = "http://www.iuii.ua.es/index.jsp?idioma=en"
            default:
                break
            }
            let wvc = WebViewController(url: URL!)
            wvc.modalTransitionStyle = .crossDissolve
            present(wvc, animated: true)
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
                let wvc = WebViewController(url: "http://mirbot.com")
                wvc.modalTransitionStyle = .crossDissolve
                present(wvc, animated: true)
            }
            else if indexPath.row == 1 {
                if let url = URL(string: "mailto://info@mirbot.com") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            else if indexPath.row == 2 {
                if let url = URL(string: "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=549105932") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
        else if indexPath.section == 3 {
            if indexPath.row == 0 {
                showAlert(kWordnetLicense)
            }
            else if indexPath.row == 1 {
                showAlert(kFGalleryLicense)
            }
            else if indexPath.row == 3 {
                showAlert(kApacheLicense)
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 62
        }
        else {
            return 50
        }
    }
}
