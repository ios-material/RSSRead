//
//  SMAddRSSViewController.m
//  RSSRead
//
//  Created by ming on 14-3-18.
//  Copyright (c) 2014年 starming. All rights reserved.
//

#import "SMAddRSSViewController.h"
#import "SMUIKitHelper.h"
#import "SMAppDelegate.h"
#import "RSS.h"
#import "SMRSSModel.h"
#import "SMAddRSSToolbar.h"
#import "SMAddRssSearchBar.h"
#import "AFNetworking.h"
#import "SMAddRssSourceModel.h"
#import "SMAddRssSoucesCell.h"
#import "MBProgressHUD+Ext.h"
#import "UIColor+RSS.h"
#import "SMRSSListViewController.h"
#import "SMTouchsView.h"


@interface SMAddRSSViewController ()<SMAddRSSToolbarDelegate,UITableViewDelegate,UITableViewDataSource,SMAddRssSoucesCellDelegate>
//@property(nonatomic,retain)NSManagedObjectContext *managedObjectContext;
@property(nonatomic,strong)MWFeedParser *feedParser;
@property(nonatomic,strong)Subscribes *subscribe;
@property(nonatomic,strong)RSS *rss;
@property(nonatomic,strong)MWFeedInfo *feedInfo;
@property(nonatomic,strong)NSMutableArray *parsedItems;
//@property(nonatomic,strong)SMAppDelegate *appDelegate;
@property(nonatomic,weak) SMAddRssSearchBar *searchBar;
@property(nonatomic,weak) SMAddRSSToolbar *toolbar;
@property(nonatomic,strong)NSMutableArray *RSSArray;
@property(nonatomic,weak)UITableView *tableView;
@property(nonatomic,strong)NSArray *keyWords;
@property(nonatomic,strong)UIView *keywordsView;
@end

@implementation SMAddRSSViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [SMUIKitHelper colorWithHexString:COLOR_BACKGROUND];
    }
    return self;
}
-(void)doBack {
    
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)loadView {
    [super loadView];
//    UISwipeGestureRecognizer *recognizer;
//    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:nil];
//    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
//    [[self view]addGestureRecognizer:recognizer];
//    recognizer = nil;
//    [self.navigationController setNavigationBarHidden:YES];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, NAVBARHEIGHT)];
    [view setBackgroundColor:[UIColor colorFromRGB:0xf6f6f6]];
    [self.view addSubview:view];
    
    //加载结果页面(tableView)
    [self setupResultView];
    //加载searchbar
    [self setupSearchBar];
    
    //添加小横条
//    [self setupLine];
    
    //加载toolbar
    [self setupToolbar];
    
    //加载指示层
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //点击close左下角通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doBack) name:@"touchCloseBtnClick" object:nil];
    
    //init
    _parsedItems = [NSMutableArray array];
    
    //Core Data
//    _appDelegate = [UIApplication sharedApplication].delegate;
//    _managedObjectContext = _appDelegate.managedObjectContext;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO];
    [super viewWillDisappear:animated];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_searchBar becomeFirstResponder];
}

- (void)btnClickAddRssUsingTag:(UIButton *)btn
{
    [btn setTitleColor:[UIColor colorFromRGB:0xcccccc] forState:UIControlStateNormal];
    SMAddRssSourceModel *searchRss = _RSSArray[btn.tag];
    _searchBar.text = searchRss.url;
    BOOL isOK =  [self addInputRSS];
    [btn setTitle:isOK ? @"已添加" : @"无法解析" forState:UIControlStateNormal];

}
#pragma mark - 根据用户输入字符串搜索RSS源
/**
 *  根据用户输入字符串搜索RSS源
 *
 *  @param str 用户输入字符串
 */
- (void)loadRssSourcesWithStr:(NSString *)str
{
    [_keywordsView removeFromSuperview];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
    /**
     *  封装请求参数
     */
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"context"] =@"";
    params[@"hl"] = @"zh_CN";
    params[@"q"]=str;
    params[@"key"] = @"ABQIAAAA6C4bndUCBastUbawfhKGURTFnqBuwPowtiyJohQxh-8vJXk-MBTetbTPnQAbLgs9lUkeE34hNbC15Q";
    params[@"v"] =@"1.0";

    [mgr GET:@"http://www.google.com/uds/GfindFeeds" parameters:params
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
     
     NSDictionary *dic = responseObject[@"responseData"];
     NSArray *rssArray = dic[@"entries"];
     NSMutableArray *Array = [NSMutableArray array];
       for (NSDictionary *dict in rssArray) {
        SMAddRssSourceModel *rssModel = [SMAddRssSourceModel rssWithDict:dict];
            [Array addObject:rssModel];
                 }
        _RSSArray = Array;
       [self.tableView reloadData];
         [MBProgressHUD  hideHUDForView:self.view animated:YES];

         
 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
     [MBProgressHUD  hideHUDForView:self.view animated:YES];
     [MBProgressHUD showShortHUDAddTo:self.view labelText:@"您的网络可能没有连接"];
 }];
}

#pragma mark - tableView代理方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _RSSArray.count;
}

//表行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 1.创建cell
    SMAddRssSoucesCell *cell = [SMAddRssSoucesCell cellWithTableView:tableView];
    cell.searchRss = self.RSSArray[indexPath.row];
    cell.delegate =self;
    cell.addButton.tag = indexPath.row;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Subscribes *aSub = _RSSArray[indexPath.row];
    SMRSSListViewController * rssListVC = [[SMRSSListViewController alloc] init];
    rssListVC.subscribeUrl = aSub.url;
    rssListVC.subscribeTitle = aSub.title;
    rssListVC.isNewVC = YES;
    rssListVC.isUnsubscribed = YES;

    [self.navigationController pushViewController:rssListVC animated:YES];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [_searchBar resignFirstResponder];

}
#pragma mark  - TextField delegate 监听键盘确认键
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    //退出键盘
    [_searchBar resignFirstResponder];
    NSString *str= _searchBar.text;
//    /**
//     *  判断用户是添加源 还是搜索源
//     */
//    NSError *error;
//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http+:[^\\s]*" options:0 error:&error];
//    /**
//     *  检查是否是网址,不是返回值为null
//     */
//    if (regex != nil) {
//        NSTextCheckingResult *result = [regex firstMatchInString:str options:0 range:NSMakeRange(0, str.length)];
//        if(result)
//        {
//             //用户添加源
//            [self addInputRSS];
//            return YES;
//        }
//    }
    //用户搜索源
    [self loadRssSourcesWithStr:str];
    
    return YES;
}

- (BOOL)addInputRSS
{
    
    //读取解析rss
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
     NSURL *feedURL = [NSURL URLWithString:_searchBar.text];
    if(!_feedParser)
        _feedParser = [[MWFeedParser alloc]initWithFeedURL:feedURL];
    
    _feedParser.delegate = self;
    _feedParser.feedParseType = ParseTypeFull;
    _feedParser.connectionType = ConnectionTypeAsynchronously;
    
    [SMFeedParserWrapper parseUrl:feedURL timeout:10.0 completion:^(NSArray *items) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];

    }];
    
    BOOL isSuccess = [_feedParser parse];
    [MBProgressHUD showShortHUDAddTo:self.view labelText: isSuccess ? @"成功添加":@"无法解析该源"];
    return isSuccess;
    
}
#pragma mark - Feed解析器代理方法
-(void)feedParserDidStart:(MWFeedParser *)parser {
    NSLog(@"Started Parsing");
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info {
    if (info.title) {
        _feedInfo = info;
    } else {
    }
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    if (item.title) {
        [_parsedItems addObject:item];
        //        NSLog(@"title:%@ author:%@ sum:%@ content:%@",item.title,item.author,item.summary,item.content);
    } else {
        NSLog(@"failed by item");
    }
}

-(void)feedParserDidFinish:(MWFeedParser *)parser {
    SMGetFetchedRecordsModel *getModel = [[SMGetFetchedRecordsModel alloc]init];
    getModel.entityName = @"Subscribes";
    getModel.predicate = [NSPredicate predicateWithFormat:@"url=%@",[_feedInfo.url absoluteString]];
    NSArray *fetchedRecords = [APP_DELEGATE getFetchedRecords:getModel];
    NSError *error;
    if (fetchedRecords.count == 0) {
        _subscribe = [NSEntityDescription insertNewObjectForEntityForName:@"Subscribes" inManagedObjectContext:APP_DELEGATE.managedObjectContext];
        _subscribe.title = _feedInfo.title ? _feedInfo.title : @"未命名";
        _subscribe.summary = _feedInfo.summary ? _feedInfo.summary : @"无描述";
        _subscribe.link = _feedInfo.link ? _feedInfo.link : @"无连接";
        _subscribe.url = [_feedInfo.url absoluteString] ? [_feedInfo.url absoluteString] : @"无连接";
        _subscribe.createDate = [NSDate date];
        _subscribe.total = [NSNumber numberWithInteger:_parsedItems.count];
        _subscribe.lastUpdateTime = [NSDate dateWithTimeIntervalSince1970:0];
        _subscribe.updateTimeInterval = @60;
        
        if (_subscribe.title) {
            [APP_DELEGATE.managedObjectContext save:&error];
            [_smAddRSSViewControllerDelegate addedRSS:_subscribe];
        }
    } else {
        //已存在订阅的情况
    }
    SMRSSModel *rssModel = [[SMRSSModel alloc]init];
    [rssModel insertRSSFeedItems:_parsedItems ofFeedUrlStr:[_feedInfo.url absoluteString]];
   // [self doBack];
}

-(void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error {
    [MBProgressHUD showShortHUDAddTo:self.view labelText:@"解析失败"];
}

/**
 *  toolbar代理方法
 */
#pragma mark - toolbar按钮点击代理方法
- (void)Toolbar:(SMAddRSSToolbar *)toolbar didClickedButtonWithString:(NSString *)str
{
    if ([str isEqualToString:@"clear"]) {
        _searchBar.text = @"";
        _searchBar.placeholder = @"请重新输入RSS";
    } else {
        _searchBar.text = [_searchBar.text stringByAppendingString:str];
    }
}

#pragma mark - 键盘显示隐藏通知
/**
 *  键盘即将显示的时候调用
 */
- (void)keyboardWillShow:(NSNotification *)note
{
    CGRect keyboardF = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.toolbar.hidden = NO;
    
    [UIView animateWithDuration:duration animations:^{
        self.toolbar.transform = CGAffineTransformMakeTranslation(0, -keyboardF.size.height-44);
    }];
}

/**
 *  键盘即将退出的时候调用
 */
- (void)keyboardWillHide:(NSNotification *)note
{
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{

        self.toolbar.transform = CGAffineTransformIdentity;
        self.toolbar.hidden = YES;
        
    }];
}

#pragma mark - 加载自定义控件
- (void)setupSearchBar
{
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(8, 0, 50, 50)];
    [closeButton setTitleColor:[UIColor rss_darkGrayColor] forState:UIControlStateNormal];
    [closeButton setTitle:@"返回" forState:UIControlStateNormal];
    [closeButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [closeButton sizeToFit];
    [closeButton addTarget:self action:@selector(doBack) forControlEvents:UIControlEventTouchUpInside];
    
    SMAddRssSearchBar *searchBar = [SMAddRssSearchBar searchBar];
    searchBar.frame = CGRectMake(closeButton.right + 12, STATUS_BAR_HEIGHT + 2, 0, 32);
    searchBar.width = SCREEN_WIDTH - searchBar.left - 6;
    searchBar.top = STATUS_BAR_HEIGHT + (44 - searchBar.height)/2;
    searchBar.delegate =self;
    self.searchBar = searchBar;
    
    closeButton.top = searchBar.top + (searchBar.height - closeButton.height)/2;
    
    SMTouchsView *touchsView = [[SMTouchsView alloc] init];
    touchsView.frame = CGRectMake(0, 0, 100, 100);
    
    [self.view addSubview:searchBar];
    [self.view addSubview:closeButton];
    [self.view addSubview:touchsView];
}
- (void)setupLine
{
    
}

- (void)setupResultView
{
    UITableView *tableView = [[UITableView alloc] init];
    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    tableView.frame = CGRectMake(0, 0, 320, self.view.frame.size.height-80);
    tableView.top = 44 + STATUS_BAR_HEIGHT;
    tableView.height = self.view.height - tableView.top;
    tableView.delegate =self;
    tableView.dataSource =self;

    _keywordsView = [[UIView alloc] initWithFrame:tableView.bounds];
    
    //介绍
    UILabel *introLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [introLabel setFont:[UIFont systemFontOfSize:16]];
    [introLabel setTextColor:[UIColor rss_darkGrayColor]];
    [introLabel setBackgroundColor:[UIColor clearColor]];
    [introLabel setText:@"这里可以搜索订阅源哦。喵。^V^"];
    [introLabel setNumberOfLines:0];
    [introLabel sizeToFit];
    introLabel.left = (_keywordsView.width - introLabel.width)/2;
    introLabel.top = tableView.top + 10;
    [_keywordsView addSubview:introLabel];
    
    //推荐搜索关键字,
    //TODO:大家有什么觉得比较常用的关键字放这里好，还有颜色
   _keyWords = @[@"科技",@"体育",@"电影",@"音乐",@"新闻",@"文学",@"艺术",@"北京",@"上海",@"杭州",@"程序员",@"云计算",@"创意",@"设计",@"创造",@"游戏",@"旅游",@"英雄联盟",@"PlayStation",@"Xbox"];
    NSArray *colorArray = @[@"#ff96aa",@"#25c0dc",@"#3edc13",@"#1dcba8"];

    CGFloat leftPadding = 10;
    CGFloat topPadding = 10;
//    CGRect rect = CGRectMake(leftPadding, topPadding, 0, 0);
    CGFloat x = leftPadding;
    CGFloat y = topPadding + introLabel.top + 20;
    
    CGSize btSize = CGSizeZero;
    
    NSInteger i = 0;
    for (NSString *kw in _keyWords) {
        UIButton *btKw = [[UIButton alloc]initWithFrame:CGRectZero];
        int r = arc4random() % [colorArray count];
        NSString *colorStr = colorArray[r];
        [btKw setBackgroundColor:[SMUIKitHelper colorWithHexString:colorStr]];
        [btKw setTitle:kw forState:UIControlStateNormal];
        [btKw setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btKw.titleLabel.font = [UIFont systemFontOfSize:14];
        btKw.size = [kw sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
        btSize = CGSizeMake(btKw.width + 10, btKw.height + 10);
        
        if (x + btSize.width + leftPadding > SCREEN_WIDTH - 15) {
            x = leftPadding;
            y += btSize.height + topPadding;
        }
        
        btKw.frame = CGRectMake(x, y, btSize.width, btSize.height);
        btKw.tag = i;
        [btKw addTarget:self action:@selector(keyWordClick:) forControlEvents:UIControlEventTouchUpInside];

        x += btSize.width + leftPadding;
        
        [_keywordsView addSubview:btKw];
        i++;
    }
    _tableView =tableView;
    [self.view addSubview:tableView];
    [self.view addSubview:_keywordsView];
}

-(void)keyWordClick:(UIButton *)sender {
    [self loadRssSourcesWithStr:_keyWords[sender.tag]];
    NSLog(@"come here");
}


/**
 *  加载toolbar
 */
-(void)setupToolbar
{
    SMAddRSSToolbar *toolbar = [[SMAddRSSToolbar alloc] init];
    toolbar.delegate =self;
    [self.view addSubview:toolbar];
    self.toolbar = toolbar;
    // 3.监听键盘的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
#pragma mark - 通知移除
- (void)dealloc
{
    _feedParser.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




@end
