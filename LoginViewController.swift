//
//  LoginViewController.swift
//  verifyhub
//
//  登录页面
//

import UIKit

class LoginViewController: BaseViewController {

    // MARK: - UI Components
    
    private let titleLabel = UILabel()
    private let cardTextField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let unbindButton = UIButton(type: .system)
    private let rechargeButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)

        // 标题
        titleLabel.text = "卡密登录"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // 输入框
        cardTextField.placeholder = "请输入卡密"
        cardTextField.borderStyle = .roundedRect
        cardTextField.font = UIFont.systemFont(ofSize: 14)
        cardTextField.autocapitalizationType = .allCharacters
        cardTextField.autocorrectionType = .no
        cardTextField.returnKeyType = .done
        cardTextField.clearButtonMode = .whileEditing
        cardTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardTextField)

        // 登录按钮
        loginButton.setTitle("登录", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1.0)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        loginButton.layer.cornerRadius = 6
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        view.addSubview(loginButton)

        // 解绑按钮
        unbindButton.setTitle("解绑", for: .normal)
        unbindButton.setTitleColor(.white, for: .normal)
        unbindButton.backgroundColor = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1.0)
        unbindButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        unbindButton.layer.cornerRadius = 6
        unbindButton.translatesAutoresizingMaskIntoConstraints = false
        unbindButton.addTarget(self, action: #selector(unbindTapped), for: .touchUpInside)
        view.addSubview(unbindButton)

        // 充值按钮
        rechargeButton.setTitle("充值", for: .normal)
        rechargeButton.setTitleColor(UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0), for: .normal)
        rechargeButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        rechargeButton.translatesAutoresizingMaskIntoConstraints = false
        rechargeButton.addTarget(self, action: #selector(rechargeTapped), for: .touchUpInside)
        view.addSubview(rechargeButton)

        // 布局约束
        setupConstraints()
    }

    // MARK: - Constraints
    
    private func setupConstraints() {
        var constraints = [NSLayoutConstraint]()

        // 标题
        if #available(iOS 11.0, *) {
            constraints.append(titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40))
        } else {
            constraints.append(titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40))
        }
        constraints.append(titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor))

        // 输入框
        constraints.append(cardTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20))
        constraints.append(cardTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30))
        constraints.append(cardTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30))
        constraints.append(cardTextField.heightAnchor.constraint(equalToConstant: 40))

        // 登录按钮（在输入框右边）
        constraints.append(loginButton.centerYAnchor.constraint(equalTo: cardTextField.centerYAnchor))
        constraints.append(loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30))
        constraints.append(loginButton.widthAnchor.constraint(equalToConstant: 60))
        constraints.append(loginButton.heightAnchor.constraint(equalToConstant: 40))

        // 解绑按钮
        constraints.append(unbindButton.topAnchor.constraint(equalTo: cardTextField.bottomAnchor, constant: 20))
        constraints.append(unbindButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30))
        constraints.append(unbindButton.widthAnchor.constraint(equalToConstant: 60))
        constraints.append(unbindButton.heightAnchor.constraint(equalToConstant: 32))

        // 充值按钮
        constraints.append(rechargeButton.centerYAnchor.constraint(equalTo: unbindButton.centerYAnchor))
        constraints.append(rechargeButton.leadingAnchor.constraint(equalTo: unbindButton.trailingAnchor, constant: 20))

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions
    
    @objc private func loginTapped() {
        guard let cardCode = cardTextField.text, !cardCode.isEmpty else {
            showAlert(title: "提示", message: "请输入卡密")
            return
        }

        loginButton.isEnabled = false

        KAuth.shared.login(cardCode: cardCode) { [weak self] success, message in
            self?.loginButton.isEnabled = true
            if success {
                // 登录成功，跳转到首页
                self?.navigateToHome()
            } else {
                self?.showAlert(title: "失败", message: message)
            }
        }
    }

    @objc private func unbindTapped() {
        guard let cardCode = cardTextField.text, !cardCode.isEmpty else {
            showAlert(title: "提示", message: "请输入卡密")
            return
        }

        showConfirmAlert(title: "确认解绑", message: "确定要解绑此卡密吗？") { [weak self] in
            guard let self = self else { return }
            self.unbindButton.isEnabled = false

            KAuth.shared.unbind(cardCode: cardCode) { success, message in
                self.unbindButton.isEnabled = true
                self.showAlert(title: success ? "成功" : "失败", message: message)
            }
        }
    }

    @objc private func rechargeTapped() {
        showRechargeDialog()
    }

    // MARK: - Navigation
    
    /// 跳转到首页
    private func navigateToHome() {
        let homeVC = HomeViewController()
        navigationController?.setViewControllers([homeVC], animated: true)
    }

    // MARK: - Dialogs
    
    private func showRechargeDialog() {
        // 先检查是否输入了卡密
        guard let cardCode = cardTextField.text, !cardCode.isEmpty else {
            showAlert(title: "提示", message: "请先输入要充值的卡密")
            return
        }
        
        let alert = UIAlertController(title: "卡密充值", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "输入充值卡密"
            textField.autocapitalizationType = .allCharacters
            textField.autocorrectionType = .no
        }

        let confirmAction = UIAlertAction(title: "确认充值", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let rechargeCode = alert?.textFields?.first?.text,
                  !rechargeCode.isEmpty else {
                self?.showAlert(title: "提示", message: "请输入充值卡密")
                return
            }

            KAuth.shared.recharge(cardCode: cardCode, rechargeCode: rechargeCode) { success, message in
                self.showAlert(title: success ? "成功" : "失败", message: message)
            }
        }

        let cancelAction = UIAlertAction(title: "取消", style: .cancel)

        alert.addAction(confirmAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func showConfirmAlert(title: String, message: String, confirmHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            confirmHandler()
        })

        present(alert, animated: true)
    }
}
