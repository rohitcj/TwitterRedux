//
//  TweetsViewController.swift
//  Twitter
//
//  Created by Rohit Jhangiani on 5/21/15.
//  Copyright (c) 2015 5TECH. All rights reserved.
//

import UIKit

let tweetsUpdatedNotification = "tweetsUpdatedNotification"

class TweetsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TweetCellDelegate, TweetComposeViewControllerDelegate {

    // outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    // controls
    var refreshControl = UIRefreshControl()
    
    // variables
    var tweets: [Tweet]?
    var replyToTweetId: String?
    var replyFromUser: String?
    var selectedRow: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 140
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        // add refresh control
        self.refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        // footer
        var tableFooterView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        var footerActivityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        footerActivityIndicator.startAnimating()
        footerActivityIndicator.center = tableFooterView.center
        tableFooterView.addSubview(footerActivityIndicator)
        self.tableView.tableFooterView = tableFooterView
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadTweets:", name: tweetsUpdatedNotification, object: nil)
        
        loadTweets(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TableView delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.tweets != nil {
            return tweets!.count
        } else {
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tweets![indexPath.row].populateCell(tableView, atRow: indexPath.row)
        cell.delegate = self
        var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "onTap:")
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        cell.profileImageView.addGestureRecognizer(tapGestureRecognizer)
        
//        if indexPath.row == self.tweets!.count - 1 {
//            loadTweets(true)
//        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        selectedRow = indexPath.row
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Misc. helpers
    
    func loadTweets(isSubsequentReload: Bool) {
        activityIndicatorView.startAnimating()
        var params: NSDictionary?
        if isSubsequentReload {
            params = ["max_id": self.tweets![self.tweets!.count-1].id!]
        }
        
        TwitterClient.sharedInstance.homeTimelineWithParams(params, completion: { (tweets, error) -> () in
            if let tweets = tweets {
                if isSubsequentReload {
                    for index in 0 ..< tweets.count {
                        self.tweets!.append(tweets[index])
                    }
                } else {
                    self.tweets = tweets
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
            }
        })
        
        activityIndicatorView.stopAnimating()
        
        if (self.refreshControl.refreshing == true) {
            self.refreshControl.endRefreshing()
        }

    }
    
    // MARK: - Refresh Control
    
    func onRefresh() {
        self.loadTweets(false)
    }
    
    // MARK: - IBActions
    
    @IBAction func onSignout(sender: AnyObject) {
        User.currentUser?.signout()
    }
    
    @IBAction func onTap(sender: AnyObject) {
        var selectedImageView = sender.view as! UIImageView
        selectedRow = selectedImageView.tag
        println("selected row: \(selectedRow!)")
        self.performSegueWithIdentifier("profileSegue", sender: self)
    }
    
    
    // MARK: - TweetCellDelegate
    
    func tweetCell(tweetCell: TweetCell, didTapReplyTweetId tweetId: String, fromUser: String) {
        let indexPath = tableView.indexPathForCell(tweetCell)
        self.replyToTweetId = self.tweets![indexPath!.row].id
        self.replyFromUser = self.tweets![indexPath!.row].user!.screenname
        self.performSegueWithIdentifier("replyTweetSegue", sender: self)
    }
    
    func tweetCell(tweetCell: TweetCell, didChangeRetweetStatus status: Bool) {
        let indexPath = tableView.indexPathForCell(tweetCell)
        self.tweets![indexPath!.row].isRetweeted = status
    }
    
    func tweetCell(tweetCell: TweetCell, didChangeFavoriteStatus status: Bool) {
        let indexPath = tableView.indexPathForCell(tweetCell)
        self.tweets![indexPath!.row].isFavorited = status
    }
    
    func tweetComposeViewController(tweetComposeViewController: TweetComposeViewController, didComposeTweet tweet: Tweet) {
        self.tweets = [tweet] + self.tweets!
        self.tableView.reloadData()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "composeTweetSegue" {
            var navigationController = segue.destinationViewController as! UINavigationController
            var tweetComposeViewController = navigationController.topViewController as! TweetComposeViewController
            tweetComposeViewController.delegate = self
        } else if segue.identifier == "replyTweetSegue" {
            var navigationController = segue.destinationViewController as! UINavigationController
            var tweetComposeViewController = navigationController.topViewController as! TweetComposeViewController
            tweetComposeViewController.replyFromUser = self.replyFromUser
            tweetComposeViewController.replyToTweetId = self.replyToTweetId
            tweetComposeViewController.delegate = self
        } else if segue.identifier == "profileSegue" {
            var profileViewController = segue.destinationViewController as! ProfileViewController
            profileViewController.user = self.tweets![selectedRow!].user!
            println("selected user: \(self.tweets![selectedRow!].user!.name!)")
        }
    }
}
