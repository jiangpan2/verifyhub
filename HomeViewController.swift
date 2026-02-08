//
//  HomeViewController.swift
//  verifyhub
//
//  首页 - 展示用户信息（登录成功后显示）
//

import UIKit

class HomeViewController: BaseViewController {

    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let cardLabel = UILabel()
    private let userIdTitleLabel = UILabel()
    private let trialTitleLabel = UILabel()
    private let cardTypeTitleLabel = UILabel()
    private let expireInfoTitleLabel = UILabel()
    
    private let userIdValueLabel = UILabel()
    private let trialValueLabel = UILabel()
    private let cardTypeValueLabel = UILabel()
    private let expireInfoValueLabel = UILabel()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .large)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchUserInfo()
    }

    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        title = "用户信息"

        // 添加退出登录按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "退出登录",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )

        setupScrollView()
        setupUserInfoViews()
        setupLoadingIndicator()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        var scrollViewTopAnchor: NSLayoutConstraint
        if #available(iOS 11.0, *) {
            scrollViewTopAnchor = scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        } else {
            scrollViewTopAnchor = scrollView.topAnchor.constraint(equalTo: view.topAnchor)
        }
        
        NSLayoutConstraint.activate([
            scrollViewTopAnchor,
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupUserInfoViews() {
        let padding: CGFloat = 20
        var previousLabel: UILabel?
        
        // 用户信息卡片背景
        let cardBackground = UIView()
        cardBackground.backgroundColor = .white
        cardBackground.layer.cornerRadius = 12
        cardBackground.layer.shadowColor = UIColor.black.cgColor
        cardBackground.layer.shadowOpacity = 0.1
        cardBackground.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardBackground.layer.shadowRadius = 4
        cardBackground.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardBackground)
        
        // 卡片标题
        cardLabel.text = "用户信息"
        cardLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        cardLabel.textColor = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1.0)
        cardLabel.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(cardLabel)
        
        // 用户ID
        setupInfoRow(
            titleLabel: userIdTitleLabel,
            valueLabel: userIdValueLabel,
            title: "用户ID",
            value: "加载中...",
            cardBackground: cardBackground,
            previousLabel: cardLabel,
            padding: padding
        )
        previousLabel = userIdTitleLabel
        
        // 是否试用
        setupInfoRow(
            titleLabel: trialTitleLabel,
            valueLabel: trialValueLabel,
            title: "是否试用",
            value: "加载中...",
            cardBackground: cardBackground,
            previousLabel: userIdTitleLabel,
            padding: padding
        )
        
        // 卡类型
        setupInfoRow(
            titleLabel: cardTypeTitleLabel,
            valueLabel: cardTypeValueLabel,
            title: "卡类型",
            value: "加载中...",
            cardBackground: cardBackground,
            previousLabel: trialTitleLabel,
            padding: padding
        )
        
        // 到期时间/剩余次数
        setupInfoRow(
            titleLabel: expireInfoTitleLabel,
            valueLabel: expireInfoValueLabel,
            title: "有效期",
            value: "加载中...",
            cardBackground: cardBackground,
            previousLabel: cardTypeTitleLabel,
            padding: padding
        )
        
        // 布局卡片
        NSLayoutConstraint.activate([
            cardBackground.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            cardBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            cardBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            cardLabel.topAnchor.constraint(equalTo: cardBackground.topAnchor, constant: 16),
            cardLabel.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor, constant: padding),
            
            userIdTitleLabel.topAnchor.constraint(equalTo: cardLabel.bottomAnchor, constant: 16),
            userIdTitleLabel.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor, constant: padding),
            
            trialTitleLabel.topAnchor.constraint(equalTo: userIdTitleLabel.bottomAnchor, constant: 12),
            trialTitleLabel.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor, constant: padding),
            
            cardTypeTitleLabel.topAnchor.constraint(equalTo: trialTitleLabel.bottomAnchor, constant: 12),
            cardTypeTitleLabel.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor, constant: padding),
            
            expireInfoTitleLabel.topAnchor.constraint(equalTo: cardTypeTitleLabel.bottomAnchor, constant: 12),
            expireInfoTitleLabel.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor, constant: padding),
            expireInfoTitleLabel.bottomAnchor.constraint(equalTo: cardBackground.bottomAnchor, constant: -16),
            
            // Value labels
            userIdValueLabel.centerYAnchor.constraint(equalTo: userIdTitleLabel.centerYAnchor),
            userIdValueLabel.trailingAnchor.constraint(equalTo: cardBackground.trailingAnchor, constant: -padding),
            
            trialValueLabel.centerYAnchor.constraint(equalTo: trialTitleLabel.centerYAnchor),
            trialValueLabel.trailingAnchor.constraint(equalTo: cardBackground.trailingAnchor, constant: -padding),
            
            cardTypeValueLabel.centerYAnchor.constraint(equalTo: cardTypeTitleLabel.centerYAnchor),
            cardTypeValueLabel.trailingAnchor.constraint(equalTo: cardBackground.trailingAnchor, constant: -padding),
            
            expireInfoValueLabel.centerYAnchor.constraint(equalTo: expireInfoTitleLabel.centerYAnchor),
            expireInfoValueLabel.trailingAnchor.constraint(equalTo: cardBackground.trailingAnchor, constant: -padding)
        ])
    }
    
    private func setupInfoRow(titleLabel: UILabel, valueLabel: UILabel, title: String, value: String, cardBackground: UIView, previousLabel: UILabel?, padding: CGFloat) {
        titleLabel.text = title + "："
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .gray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(titleLabel)
        
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = .black
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(valueLabel)
        
        if let previous = previousLabel {
            titleLabel.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 12).isActive = true
        }
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Data Fetching
    
    private func fetchUserInfo() {
        loadingIndicator.startAnimating()
        
        NetworkManager.shared.request(.userInfo()) { [weak self] (result: Result<ApiResult<UserInfoResponse>, Error>) in
            self?.loadingIndicator.stopAnimating()
            
            switch result {
            case .success(let response):
                if response.code == 200, let userInfo = response.data {
                    self?.updateUserInfo(userInfo)
                } else {
                    self?.showAlert(title: "提示", message: response.msg ?? "获取用户信息失败")
                }
                
            case .failure(let error):
                self?.showAlert(title: "错误", message: error.localizedDescription)
            }
        }
    }
    
    private func updateUserInfo(_ userInfo: UserInfoResponse) {
        userIdValueLabel.text = userInfo.userIdDescription
        trialValueLabel.text = userInfo.trialDescription
        cardTypeValueLabel.text = userInfo.cardTypeDescription
        expireInfoValueLabel.text = userInfo.expireInfoDescription
    }

    // MARK: - Actions
    
    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "确认退出", message: "确定要退出登录吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.logout()
        })
        
        present(alert, animated: true)
    }
    
    private func logout() {
        // 停止心跳
        HeartbeatManager.shared.stop()
        
        // 清理token
        KauthCore.shared.clearAll()
        
        // 跳转到登录页
        guard let window = UIApplication.shared.windows.first else { return }
        
        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = navController
        }, completion: nil)
    }

    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
