//
//  GoogleSearchViewController.m
//  sticker
//
//  Created by 李健銘 on 2014/3/8.
//  Copyright (c) 2014年 TakoBear. All rights reserved.
//

#import "GoogleSearchViewController.h"
#import "ASIHTTPRequest.h"
#import "PhotoViewCell.h"
#import "UIImageView+WebCache.h"
#import "EditViewController.h"


#define kGOOGLE_IMAGE_SEARCH_API @"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q="
#define kSEARCH_BAR_TAG 101

@interface GoogleSearchViewController ()<UISearchBarDelegate,UICollectionViewDataSource,UICollectionViewDelegate, ASIProgressDelegate>
{
    NSMutableArray *tbImageURLArray;
    NSMutableArray *originImageURLArray;
    UICollectionView *googleCollectionView;
    int searchCount;
    NSString *inputString;
    UITapGestureRecognizer *gestureTextField;
}

@end

@implementation GoogleSearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    tbImageURLArray = [NSMutableArray new];
    originImageURLArray = [NSMutableArray new];
    
    //To avoid clear background
    self.view.backgroundColor = [UIColor whiteColor];
    UIView *whiteView = [[UIView alloc] initWithFrame:self.view.bounds];
    whiteView.backgroundColor = [UIColor colorWithRed:0.4 green:0.6 blue:0.8 alpha:0.3];
    [self.view addSubview:whiteView];
    [whiteView release];
    
    //Create gesture to dismiss searchbar
    gestureTextField = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboadOfSearchBar)];
    
    //Create Searchbar
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width-40, 40)];
    searchBar.center = CGPointMake(self.view.center.x,searchBar.center.y);
    searchBar.delegate = self;
    searchBar.placeholder = @"start to search";
    searchBar.barTintColor = [UIColor whiteColor];
    searchBar.tag = kSEARCH_BAR_TAG;
    [self.navigationController.navigationBar addSubview:searchBar];
    [searchBar becomeFirstResponder];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont systemFontOfSize:16]];
    [searchBar release];
    
    //Create Collection View
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(100,100)];
    [flowLayout setMinimumInteritemSpacing:0.0f];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    googleCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(4, 70, self.view.bounds.size.width-8, self.view.bounds.size.height-70) collectionViewLayout:flowLayout];
    googleCollectionView.delegate = self;
    googleCollectionView.dataSource = self;
    googleCollectionView.backgroundColor = [UIColor clearColor];
    [googleCollectionView registerClass:[PhotoViewCell class] forCellWithReuseIdentifier:@"googleImageCell"];
    
    [self.view addSubview:googleCollectionView];
    [googleCollectionView release];
    
}

- (void)dealloc
{
    [super dealloc];
    
    [tbImageURLArray removeAllObjects];
    [originImageURLArray removeAllObjects];
    
    [tbImageURLArray release];
    [originImageURLArray release];
    [inputString release];
    [gestureTextField release];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UISearchBar Delegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [self.view addGestureRecognizer:gestureTextField];
    [searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    [self.view removeGestureRecognizer:gestureTextField];
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *text = searchBar.text;
    
    if (text.length == 0 ) {
        [searchBar resignFirstResponder];
        return;
    }
    
    [tbImageURLArray removeAllObjects];
    [originImageURLArray removeAllObjects];
    inputString = [[text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] retain];
    //retain to avoid crash!
    NSString *searchString = [NSString stringWithFormat:@"%@%@&rsz=8",kGOOGLE_IMAGE_SEARCH_API,inputString];
    NSURL *searchURL = [NSURL URLWithString:searchString];
    searchCount = 8;
    [self googleSearchWithUrl:searchURL];
    
    [searchBar resignFirstResponder];
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    [searchBar resignFirstResponder];
}

- (void)dismissKeyboadOfSearchBar
{
    UISearchBar *searchBar = (UISearchBar *)[self.navigationController.navigationBar viewWithTag:kSEARCH_BAR_TAG];
    [searchBar resignFirstResponder];
    [self.view removeGestureRecognizer:gestureTextField];
}

#pragma mark - ASIHTTPRequest

- (void)googleSearchWithUrl:(NSURL *)searchURL
{
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:searchURL];
    [request setRequestMethod:@"GET"];
    [request setTimeOutSeconds:10.0f];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(didFinishRequest:)];
    [request setDidFailSelector:@selector(didFailRequest:)];
    [request setDownloadProgressDelegate:self];
    [request startAsynchronous];
    
    [request release];
    
}

- (void)didFinishRequest:(ASIHTTPRequest *)request
{
    NSData *data = [request responseData];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSDictionary *responseDataDic = [json objectForKey:@"responseData"];
    if (responseDataDic == (NSDictionary *)[NSNull null]){
        return;
    }
    NSArray *resultsArray = [responseDataDic objectForKey:@"results"];
    NSEnumerator *enumerator = [resultsArray objectEnumerator];
    NSDictionary *result;
    int count = 0;
    while (result = [enumerator nextObject]) {
        result = [resultsArray objectAtIndex:count];
        if (result == (NSDictionary *)[NSNull null]){
            [self searchMoreImage];
            return;
        }
        [tbImageURLArray addObject:[result objectForKey:@"tbUrl"]];
        [originImageURLArray addObject:[result objectForKey:@"url"]];
        count ++;
    }
    if (searchCount < 64) {
        [self searchMoreImage];
    } else {
        [googleCollectionView reloadData];
        [googleCollectionView setContentOffset:CGPointZero animated:YES];
    }
}

- (void)didFailRequest:(ASIHTTPRequest *)request
{
    NSError *error = request.error;
    searchCount -= 8;
    NSLog(@"error = %@",error);
}

- (void)searchMoreImage
{
    NSString *searchString = [NSString stringWithFormat:@"%@%@&start=%d&rsz=8",kGOOGLE_IMAGE_SEARCH_API,inputString,searchCount];
    NSURL *searchURL = [NSURL URLWithString:searchString];
    [self googleSearchWithUrl:searchURL];
    searchCount += 8;
}
#pragma mark - CollectionView dataSource & Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return tbImageURLArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    __block PhotoViewCell *cell = (PhotoViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"googleImageCell" forIndexPath:indexPath];
    cell.isProgress = YES;
    NSURL *imageURL = [NSURL URLWithString:[tbImageURLArray objectAtIndex:indexPath.item]];
    [cell.imgView setContentMode:UIViewContentModeScaleAspectFill];
    [cell.imgView setClipsToBounds:YES];
    [cell.imgView setImageWithURL:imageURL placeholderImage:nil
                          options:0
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                            
                             if (expectedSize > 0) {
                                 CGFloat progress = (CGFloat)receivedSize / (CGFloat)expectedSize;
                                 [cell.progressView setProgress:progress animated:YES];
                             }
                             
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [cell.progressView setProgress:0.0f animated:YES];
        [cell.imgView setImage:image];
    }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *imageURL = [NSURL URLWithString:[originImageURLArray objectAtIndex:indexPath.item]];
    EditViewController *editViewController = [[EditViewController alloc] initWithURL:imageURL];
    [self.navigationController pushViewController:editViewController animated:YES];
    
    [editViewController release];
}


@end