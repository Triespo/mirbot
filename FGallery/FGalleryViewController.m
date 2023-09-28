//
//  FGalleryViewController.m
//  TNF_Trails
//
//  Created by Grant Davis on 5/19/10.
//  Copyright 2010 Factory Design Labs. All rights reserved.
//
//   Modified by Antonio Pertusa

#import "FGalleryViewController.h"
#import "mirbot-Swift.h"

#define kThumbnailSize 100
#define kThumbnailSpacing 4
#define kCaptionPadding 3
#define kToolbarHeight 40

@interface FGalleryViewController (Private)

// general
- (void)buildViews;

- (void)layoutViews;
- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation;
- (void)updateButtons;
- (void)layoutButtons;
- (void)updateScrollSize;
- (void)updateCaption;
- (void)resizeImageViewsWithRect:(CGRect)rect;
- (void)resetImageViewZoomLevels;

- (void)enterFullscreen;
- (void)exitFullscreen;
- (void)enableApp;
- (void)disableApp;

- (void)positionInnerContainer;
- (void)positionScroller;
- (void)positionToolbar;
- (void)resizeThumbView;

// thumbnails
- (void)toggleThumbView;
- (void)buildThumbsViewPhotos;
- (void)arrangeThumbs;

- (void)loadAllThumbViewPhotos;

- (void)preloadThumbnailImages;
- (void)curlThumbView;
- (void)uncurlThumbView;
- (void)unloadFullsizeImageWithIndex:(NSUInteger)index;

- (void)scrollingHasEnded;

- (void)handleSeeAllTouch:(id)sender;
- (void)handleThumbClick:(id)sender;

- (FGalleryPhoto*)createGalleryPhotoForIndex:(NSUInteger)index;

- (void)loadThumbnailImageWithIndex:(NSUInteger)index;
- (void)loadFullsizeImageWithIndex:(NSUInteger)index;

@end



@implementation FGalleryViewController
@synthesize galleryID;
@synthesize photoSource = _photoSource, currentIndex = _currentIndex, thumbsView = _thumbsView, toolBar = _toolbar, classname=_classname, classid=_classid;



#pragma mark - Public Methods
/////////////////

-(void)showWikiView:(id)sender
{
    WebViewController *wvc=[Utilities createWikiView:self.classname];
    wvc.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
    [self presentViewController:wvc animated:YES completion:nil];
}

-(void)showTreeView:(id)sender
{
    TreeViewController *tvc=[[TreeViewController alloc] initWithId:self.classid withLemma:self.classname];
    
    tvc.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
    tvc.modalPresentationStyle=UIModalPresentationFormSheet;
    
    [self presentViewController:tvc animated:YES completion:nil];
}


-(void)createAltToolBar
{
    self.altToolBar=[[UIToolbar alloc] initWithFrame:CGRectZero];
    
    /*   UIButton *sbutton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
     [sbutton setImage:[UIImage imageNamed:@"wikipedia.png"] forState:UIControlStateNormal];
     [sbutton addTarget:self action:@selector(showWikiView:) forControlEvents:UIControlEventTouchUpInside];
     sbutton.showsTouchWhenHighlighted=YES;
     UIBarButtonItem *wiki = [[UIBarButtonItem alloc] initWithCustomView:sbutton];
     */
    UIBarButtonItem *wiki=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"wikipedia.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showWikiView:)];
    /*
     UIButton *tbutton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 21, 21)];
     [tbutton setImage:[UIImage imageNamed:@"book.png"] forState:UIControlStateNormal];
     [tbutton addTarget:self action:@selector(showTreeView:) forControlEvents:UIControlEventTouchUpInside];
     tbutton.showsTouchWhenHighlighted=YES;
     UIBarButtonItem *tree = [[UIBarButtonItem alloc] initWithCustomView:tbutton];
     */
    UIBarButtonItem *tree=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"book.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showTreeView:)];
    
    UIBarButtonItem *flexibleSpace=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    
    // IOS7 self.altToolBar.barStyle =  UIBarStyleBlackTranslucent;
    self.altToolBar.autoresizingMask=UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    self.altToolBar.items=[NSArray arrayWithObjects:flexibleSpace, wiki, flexibleSpace, tree, flexibleSpace, nil];
}

///////////////////

-(void)remove
{
    [self.view removeFromSuperview];
}

-(void)reload
{
    [self.view setNeedsDisplay];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if((self = [super initWithNibName:nil bundle:nil])) {
        
        // init gallery id with our memory address
        self.galleryID                        = [NSString stringWithFormat:@"%p", self];
        
        // hide any silly bottom bars.
        self.hidesBottomBarWhenPushed    = YES;
        
        _prevStatusStyle                    = [[UIApplication sharedApplication] statusBarStyle];
        
        // create storage
        _currentIndex                        = 0;
        _photoLoaders                        = [[NSMutableDictionary alloc] init];
        _photoViews                            = [[NSMutableArray alloc] init];
        _photoThumbnailViews                = [[NSMutableArray alloc] init];
        _barItems                            = [[NSMutableArray alloc] init];
        
        // create public objects first so they're available for custom configuration right away. positioning comes later.
        _container                            = [[UIView alloc] initWithFrame:CGRectZero];
        _innerContainer                        = [[UIView alloc] initWithFrame:CGRectZero];
        _scroller                            = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _thumbsView                            = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _toolbar                            = [[UIToolbar alloc] initWithFrame:CGRectZero];
        _captionContainer                    = [[UIView alloc] initWithFrame:CGRectZero];
        _caption                            = [[UILabel alloc] initWithFrame:CGRectZero];
        
        // IOS7 _toolbar.barStyle            =  UIBarStyleBlackTranslucent;
        // IOS7 _container.backgroundColor            = [UIColor blackColor];
        
        // listen for container frame changes so we can properly update the layout during auto-rotation or going in and out of fullscreen
        [_container addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
        
        /*
         // debugging:
         _container.layer.borderColor = [[UIColor yellowColor] CGColor];
         _container.layer.borderWidth = 1.0;
         
         _innerContainer.layer.borderColor = [[UIColor greenColor] CGColor];
         _innerContainer.layer.borderWidth = 1.0;
         
         _scroller.layer.borderColor = [[UIColor redColor] CGColor];
         _scroller.layer.borderWidth = 2.0;
         */
        
        // setup scroller
        _scroller.delegate                            = self;
        _scroller.pagingEnabled                        = YES;
        _scroller.showsVerticalScrollIndicator        = NO;
        _scroller.showsHorizontalScrollIndicator    = NO;
        
        // setup caption
        _captionContainer.backgroundColor            = [UIColor colorWithWhite:0.0 alpha:.35];
        _captionContainer.hidden                    = YES;
        _captionContainer.userInteractionEnabled    = NO;
        _captionContainer.exclusiveTouch            = YES;
        _caption.font                                = [UIFont systemFontOfSize:14.0];
        _caption.textColor                            = [UIColor whiteColor];
        _caption.backgroundColor                    = [UIColor clearColor];
        _caption.textAlignment                        = NSTextAlignmentCenter;
        _caption.shadowColor                        = [UIColor blackColor];
        _caption.shadowOffset                        = CGSizeMake( 1, 1 );
        
        // make things flexible
        _container.autoresizesSubviews                = NO;
        _innerContainer.autoresizesSubviews            = NO;
        _scroller.autoresizesSubviews                = NO;
        _container.autoresizingMask                    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        // setup thumbs view
        _thumbsView.backgroundColor                    = [UIColor grayColor];
        _thumbsView.hidden                            = YES;
        _thumbsView.contentInset                    = UIEdgeInsetsMake( kThumbnailSpacing, kThumbnailSpacing, kThumbnailSpacing, kThumbnailSpacing);
    }
    return self;
}


- (id)initWithPhotoSource:(NSObject<FGalleryViewControllerDelegate>*)photoSrc
{
    if((self = [self initWithNibName:nil bundle:nil])) {
        
        _photoSource = photoSrc;
    }
    return self;
}


- (id)initWithPhotoSource:(NSObject<FGalleryViewControllerDelegate>*)photoSrc barItems:(NSArray*)items
{
    [self createAltToolBar];
    
    if((self = [self initWithPhotoSource:photoSrc])) {
        
        [_barItems addObjectsFromArray:items];
    }
    return self;
}




- (void)loadView
{
    //self.navigationController.navigationBar.translucent = NO;
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // setup container
    self.view = _container;
    
    // add items to their containers
    [_container addSubview:_innerContainer];
    [_container addSubview:_thumbsView];
    
    [_innerContainer addSubview:_scroller];
    [_innerContainer addSubview:_toolbar];
    
    [_toolbar addSubview:_captionContainer];
    [_captionContainer addSubview:_caption];
    
    // create buttons for toolbar
    UIImage *leftIcon = [UIImage imageNamed:@"photo-gallery-left.png"];
    UIImage *rightIcon = [UIImage imageNamed:@"photo-gallery-right.png"];
    _nextButton = [[UIBarButtonItem alloc] initWithImage:rightIcon style:UIBarButtonItemStylePlain target:self action:@selector(next)];
    _prevButton = [[UIBarButtonItem alloc] initWithImage:leftIcon style:UIBarButtonItemStylePlain target:self action:@selector(previous)];
    
    
    
    // add prev next to front of the array
    [_barItems insertObject:_nextButton atIndex:0];
    [_barItems insertObject:_prevButton atIndex:0];
    
    
    _prevNextButtonSize = leftIcon.size.width;
    
    // set buttons on the toolbar.
    [_toolbar setItems:_barItems animated:NO];
    
    // create layer for the thumbnails
    _isThumbViewShowing = NO;
    
    // create the image views for each photo
    [self buildViews];
    
    // create the thumbnail views
    [self buildThumbsViewPhotos];
    
    // start loading thumbs
    [self preloadThumbnailImages];
    
    // View all
    [self handleSeeAllTouch:self];
    
}




- (void)viewWillAppear:(BOOL)animated
{
    //    NSLog(@"<ViewWillAppear>");
    
    _isActive = YES;
    
    [super viewWillAppear:animated]; // according to docs, we have to call this.
    
    [self layoutViews];
    
    [[UIApplication sharedApplication] setStatusBarHidden: NO withAnimation: UIStatusBarAnimationFade]; // 3.2+
    // update status bar to be see-through
    //  if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
    //      [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
    
    
    // init with next on first run.
    if( _currentIndex == -1 ) [self next];
    else [self gotoImageByIndex:_currentIndex animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    _isActive = NO;
    
    [super viewWillDisappear:animated];
    
    // IOS7 [[UIApplication sharedApplication] setStatusBarStyle:_prevStatusStyle animated:animated];
}


- (void)resizeImageViewsWithRect:(CGRect)rect
{
    // resize all the image views
    NSUInteger i, count = [_photoViews count];
    float dx = 0;
    for (i = 0; i < count; i++) {
        FGalleryPhotoView * photoView = [_photoViews objectAtIndex:i];
        photoView.frame = CGRectMake(dx, 0, rect.size.width, rect.size.height );
        dx += rect.size.width;
    }
}

- (void)resetImageViewZoomLevels
{
    // resize all the image views
    NSUInteger i, count = [_photoViews count];
    for (i = 0; i < count; i++) {
        FGalleryPhotoView * photoView = [_photoViews objectAtIndex:i];
        [photoView resetZoom];
    }
}


- (void)removeImageAtIndex:(NSUInteger)index
{
    // remove the image and thumbnail at the specified index.
    FGalleryPhotoView *imgView = [_photoViews objectAtIndex:index];
    FGalleryPhotoView *thumbView = [_photoThumbnailViews objectAtIndex:index];
    FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)index]];
    
    //NSLog(@"Requested delete element %i from %i",index,[_photoSource numberOfPhotosForPhotoGallery:self]);
    
    [photo unloadFullsize];
    [photo unloadThumbnail];
    
    [imgView removeFromSuperview];
    [thumbView removeFromSuperview];
    
    [_photoViews removeObjectAtIndex:index];
    [_photoThumbnailViews removeObjectAtIndex:index];
    [_photoLoaders removeObjectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)index]];
    
    // API: ADDED TO THE LIBRARY (UPDATE ALL TAGS OF PHOTOS FOR NEXT QUERY)
    for (NSInteger i=_currentIndex; i<[_photoSource numberOfPhotosForPhotoGallery:self]; i++)
    {
        FGalleryPhotoView *photoView = [_photoViews objectAtIndex:i];
        photoView.button.tag--;
        
        FGalleryPhotoView *thumbView=[_photoThumbnailViews objectAtIndex:i];
        thumbView.tag--;
        
        FGalleryPhoto *photoLoader = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%li", (long)i+1]];
        if (photoLoader!=nil) photoLoader.tag--;
    }
    
    // API: UPDATE DICTIONARY INDEXES (PHOTOLOADERS)
    NSMutableDictionary *photoLoadersCopy=[[NSMutableDictionary alloc] init];
    for (NSInteger i=0; i<_currentIndex; i++)
        [photoLoadersCopy setObject:[_photoLoaders objectForKey:[NSString stringWithFormat:@"%li",(long)i]] forKey:[NSString stringWithFormat:@"%li",(long)i]];
    for (NSInteger i=_currentIndex+1; i<[_photoSource numberOfPhotosForPhotoGallery:self]; i++)
        [photoLoadersCopy setObject:[_photoLoaders objectForKey:[NSString stringWithFormat:@"%li",(long)i]] forKey: [NSString stringWithFormat:@"%li",(long)i-1]];
    _photoLoaders=photoLoadersCopy;
    
    // Update index
    [self gotoImageByIndex:_currentIndex animated:NO];
    
    /// End added
    [self layoutViews];
    [self updateButtons];
    [self updateTitle];
    
    [self.view setNeedsDisplay];
    [self.view setNeedsLayout];
}


- (void)next
{
    NSUInteger numberOfPhotos = [_photoSource numberOfPhotosForPhotoGallery:self];
    NSUInteger nextIndex = _currentIndex+1;
    
    // don't continue if we're out of images.
    if( nextIndex >= numberOfPhotos )
    {
        nextIndex = numberOfPhotos-1;
        return;
    }
    
    [self gotoImageByIndex:nextIndex animated:NO];
}



- (void)previous
{
    NSUInteger prevIndex = _currentIndex-1;
    [self gotoImageByIndex:prevIndex animated:NO];
}



- (void)gotoImageByIndex:(NSUInteger)index animated:(BOOL)animated
{
    //NSLog(@"gotoImageByIndex: %i, out of %i", index, [_photoSource numberOfPhotosForPhotoGallery:self]);
    
    NSUInteger numPhotos = [_photoSource numberOfPhotosForPhotoGallery:self];
    
    // constrain index within our limits
    if( index >= numPhotos ) index = numPhotos - 1;
    
    
    if( numPhotos == 0 ) {
        
        // no photos!
        _currentIndex = -1;
    }
    else {
        
        // clear the fullsize image in the old photo
        [self unloadFullsizeImageWithIndex:_currentIndex];
        
        _currentIndex = index;
        [self moveScrollerToCurrentIndexWithAnimation:animated];
        [self updateTitle];
        
        if( !animated )    {
            [self preloadThumbnailImages];
            [self loadFullsizeImageWithIndex:index];
        }
    }
    [self updateButtons];
    [self updateCaption];
}





// adjusts size and positioning of everything
- (void)layoutViews
{
    [self positionInnerContainer];
    
    [self positionScroller];
    
    [self resizeThumbView];
    
    [self positionToolbar];
    
    [self positionAltToolbar];
    
    [self updateScrollSize];
    
    [self updateCaption];
    
    [self resizeImageViewsWithRect:_scroller.frame];
    
    [self layoutButtons];
    
    [self arrangeThumbs];
    
    [self moveScrollerToCurrentIndexWithAnimation:NO];
    
}




#pragma mark - Private Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"frame"])
    {
        [self layoutViews];
    }
}


- (void)positionInnerContainer
{
    CGRect screenFrame;
    
    //[self.view layoutIfNeeded];
    
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
        screenFrame=self.view.frame;
    else
        screenFrame = [[UIScreen mainScreen] bounds];
    
    CGRect innerContainerRect;
    
    innerContainerRect = CGRectMake( 0, _container.frame.size.height - screenFrame.size.height, _container.frame.size.width, screenFrame.size.height );
    
    _innerContainer.frame = innerContainerRect;
    
}

- (void)positionScroller
{
    CGRect screenFrame;
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
        screenFrame=self.view.frame;
    else
        screenFrame = [[UIScreen mainScreen] bounds];
    
    CGRect scrollerRect;
    
    scrollerRect = CGRectMake( 0, 0, screenFrame.size.width, screenFrame.size.height );
    
    _scroller.frame = scrollerRect;
    
}

- (void)positionToolbar
{
    _toolbar.frame = CGRectMake( 0, _scroller.frame.size.height-kToolbarHeight, _scroller.frame.size.width, kToolbarHeight );
}

- (void)positionAltToolbar
{
    self.altToolBar.frame = CGRectMake( 0, _container.frame.size.height-kToolbarHeight, _container.frame.size.width, kToolbarHeight );
}

- (void)resizeThumbView
{
    _thumbsView.frame = CGRectMake( 0, 0, _container.frame.size.width, _container.frame.size.height );
}


- (void)enterFullscreen
{
    _isFullscreen = YES;
    
    [self disableApp];
    
    UIApplication* application = [UIApplication sharedApplication];
    if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
        [[UIApplication sharedApplication] setStatusBarHidden: NO withAnimation: UIStatusBarAnimationFade]; // 3.2+
    }
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    
    [UIView beginAnimations:@"galleryOut" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(enableApp)];
    _toolbar.alpha = 0.0;
    _captionContainer.alpha = 0.0;
    [UIView commitAnimations];
}



- (void)exitFullscreen
{
    _isFullscreen = NO;
    
    [self disableApp];
    
    UIApplication* application = [UIApplication sharedApplication];
    if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade]; // 3.2+
    }
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    
    [UIView beginAnimations:@"galleryIn" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(enableApp)];
    _toolbar.alpha = 1.0;
    _captionContainer.alpha = 1.0;
    [UIView commitAnimations];
}



- (void)enableApp
{
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}
- (void)disableApp
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}


- (void)didTapPhotoView:(FGalleryPhotoView*)photoView
{
    // don't change when scrolling
    if( (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) || _isScrolling || !_isActive ) return;
    
    // toggle fullscreen.
    if( _isFullscreen == NO ) {
        
        [self enterFullscreen];
    }
    else {
        
        [self exitFullscreen];
    }
}


- (void)updateCaption
{
    if([_photoSource numberOfPhotosForPhotoGallery:self] > 0 )
    {
        if([_photoSource respondsToSelector:@selector(photoGallery:captionForPhotoAtIndex:)])
        {
            NSString *caption = [_photoSource photoGallery:self captionForPhotoAtIndex:_currentIndex];
            
            if([caption length] > 0 )
            {
                float captionWidth = _container.frame.size.width-kCaptionPadding*2;
                
                // iOS6
                //CGSize textSize = [caption sizeWithFont:_caption.font];
                
                CGSize textSize = [caption sizeWithAttributes:@{NSFontAttributeName:_caption.font}];
                
                NSUInteger numLines = ceilf( textSize.width / captionWidth );
                NSInteger height = ( textSize.height + kCaptionPadding ) * numLines;
                
                _caption.numberOfLines = numLines;
                _caption.text = caption;
                
                NSInteger containerHeight = height+kCaptionPadding*2;
                _captionContainer.frame = CGRectMake(0, -containerHeight, _container.frame.size.width, containerHeight );
                _caption.frame = CGRectMake(kCaptionPadding, kCaptionPadding, captionWidth, height );
                
                // show caption bar
                _captionContainer.hidden = NO;
            }
            else {
                
                // hide it if we don't have a caption.
                _captionContainer.hidden = YES;
            }
        }
    }
}


- (void)updateScrollSize
{
    float contentWidth = _scroller.frame.size.width * [_photoSource numberOfPhotosForPhotoGallery:self];
    [_scroller setContentSize:CGSizeMake(contentWidth, _scroller.frame.size.height)];
}


- (void)updateTitle
{
    if (_isThumbViewShowing)
        [self setTitle:self.classname];
    
    else [self setTitle:[NSString stringWithFormat:@"%li of %i", (long)_currentIndex+1, [_photoSource numberOfPhotosForPhotoGallery:self]]];
}



- (void)updateButtons
{
    _prevButton.enabled = ( _currentIndex <= 0 ) ? NO : YES;
    _nextButton.enabled = ( _currentIndex >= [_photoSource numberOfPhotosForPhotoGallery:self]-1 ) ? NO : YES;
}

- (void)layoutButtons
{
    NSUInteger buttonWidth = roundf( _toolbar.frame.size.width / [_barItems count] - _prevNextButtonSize * .5);
    
    // loop through all the button items and give them the same width
    NSUInteger i, count = [_barItems count];
    for (i = 0; i < count; i++) {
        UIBarButtonItem *btn = [_barItems objectAtIndex:i];
        btn.width = buttonWidth;
    }
    [_toolbar setNeedsLayout];
}

- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation
{
    int xp = _scroller.frame.size.width * _currentIndex;
    [_scroller scrollRectToVisible:CGRectMake(xp, 0, _scroller.frame.size.width, _scroller.frame.size.height) animated:animation];
    _isScrolling = animation;
}



- (void)handleSeeAllTouch:(id)sender
{
    // show thumb view
    [self toggleThumbView];
    
    // tell thumbs that havent loaded to load
    [self loadAllThumbViewPhotos];
}




// creates all the image views for this gallery
- (void)buildViews
{
    NSUInteger i, count = [_photoSource numberOfPhotosForPhotoGallery:self];
    
    //NSLog(@"Number of photos in source=%i",count);
    
    for (i = 0; i < count; i++) {
        FGalleryPhotoView *photoView = [[FGalleryPhotoView alloc] initWithFrame:CGRectZero];
        photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        photoView.autoresizesSubviews = YES;
        photoView.photoDelegate = self;
        [_scroller addSubview:photoView];
        [_photoViews addObject:photoView];
    }
}



- (void)buildThumbsViewPhotos
{
    
    NSUInteger i, count = [_photoSource numberOfPhotosForPhotoGallery:self];
    for (i = 0; i < count; i++) {
        
        FGalleryPhotoView *thumbView = [[FGalleryPhotoView alloc] initWithFrame:CGRectZero target:self action:@selector(handleThumbClick:)];
        [thumbView setContentMode:UIViewContentModeScaleAspectFill];
        [thumbView setClipsToBounds:YES];
        [thumbView setTag:i];
        [_thumbsView addSubview:thumbView];
        [_photoThumbnailViews addObject:thumbView];
    }
}



- (void)arrangeThumbs
{
    float dx = 0.0;
    float dy = 0.0;
    // loop through all thumbs to size and place them
    NSUInteger i, count = [_photoThumbnailViews count];
    for (i = 0; i < count; i++) {
        FGalleryPhotoView *thumbView = [_photoThumbnailViews objectAtIndex:i];
        [thumbView setBackgroundColor:[UIColor grayColor]];
        
        // create new frame
        thumbView.frame = CGRectMake( dx, dy, kThumbnailSize, kThumbnailSize);
        
        // increment position
        dx += kThumbnailSize + kThumbnailSpacing;
        
        // check if we need to move to a different row
        if( dx + kThumbnailSize + kThumbnailSpacing > _thumbsView.frame.size.width - kThumbnailSpacing )
        {
            dx = 0.0;
            dy += kThumbnailSize + kThumbnailSpacing;
        }
    }
    
    // set the content size of the thumb scroller
    [_thumbsView setContentSize:CGSizeMake( _thumbsView.frame.size.width - ( kThumbnailSpacing*2 ), dy + kThumbnailSize + kThumbnailSpacing )];
}



- (void)toggleThumbView
{
    if( !_isThumbViewShowing )
    {
        
        _isThumbViewShowing = YES;
        [self updateTitle];
        [self arrangeThumbs];
        [self uncurlThumbView];
        self.navigationItem.rightBarButtonItem=nil;
        self.navigationItem.hidesBackButton = NO;
        
        /* IOS7    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
         */
        // API
        [_container addSubview:self.altToolBar];
        
        
    }
    else
    {
        _isThumbViewShowing = NO;
        [self updateTitle];
        [self curlThumbView];
        
        [self.altToolBar removeFromSuperview];
        
        // add top right nav button for thumbs view
        UIBarButtonItem *seeall = [[UIBarButtonItem alloc] initWithTitle:@"See All" style:UIBarButtonItemStylePlain target:self action:@selector(handleSeeAllTouch:)];
        self.navigationItem.rightBarButtonItem = seeall;
        self.navigationItem.hidesBackButton = YES;
        
        /* IOS7        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
         */    }
}



- (void)curlThumbView
{
    // do curl animation
    [UIView beginAnimations:@"curl" context:nil];
    [UIView setAnimationDuration:.666];
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:_thumbsView cache:YES];
    [_thumbsView setHidden:YES];
    [UIView commitAnimations];
}



- (void)uncurlThumbView
{
    // do curl animation
    [UIView beginAnimations:@"uncurl" context:nil];
    [UIView setAnimationDuration:.666];
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:_thumbsView cache:YES];
    [_thumbsView setHidden:NO];
    [UIView commitAnimations];
}



- (void)handleThumbClick:(id)sender
{
    
    FGalleryPhotoView *photoView = (FGalleryPhotoView*)[(UIButton*)sender superview];
    
    [self toggleThumbView];
    [self gotoImageByIndex:photoView.tag animated:NO];
}




#pragma mark - Image Loading


- (void)preloadThumbnailImages
{
    NSUInteger index = _currentIndex;
    NSUInteger count = [_photoViews count];
    // make sure the images surrounding the current index have thumbs loading
    NSUInteger nextIndex = index + 1;
    NSUInteger prevIndex = index - 1;
    
    // the preload count indicates how many images surrounding the current photo will get preloaded.
    // a value of 2 at maximum would preload 4 images, 2 in front of and two behind the current image.
    NSUInteger preloadCount = 1;
    
    
    FGalleryPhoto *photo;
    
    
    // check to see if the current image thumb has been loaded
    photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)index]];
    
    if( !photo )
    {
        //        NSLog(@"preloading current image thumbnail!");
        [self loadThumbnailImageWithIndex:index];
        photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)index]];
    }
    else if( !photo.hasThumbLoaded && !photo.isThumbLoading )
        [photo loadThumbnail];
    
    
    NSUInteger curIndex = prevIndex;
    while( curIndex > -1 && curIndex > prevIndex - preloadCount )
    {
        photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)curIndex]];
        
        if( !photo ) {
            [self loadThumbnailImageWithIndex:curIndex];
            photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)curIndex]];
        }
        
        else if( !photo.hasThumbLoaded && !photo.isThumbLoading )
            [photo loadThumbnail];
        
        curIndex--;
    }
    
    curIndex = nextIndex;
    while( curIndex < count && curIndex < nextIndex + preloadCount )
    {
        photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)curIndex]];
        
        if( !photo ) {
            [self loadThumbnailImageWithIndex:curIndex];
            photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)curIndex]];
        }
        
        else if( !photo.hasThumbLoaded && !photo.isThumbLoading )
            [photo loadThumbnail];
        //        NSLog(@"next thumbnail %i loading", photo.tag );
        
        curIndex++;
    }
}


- (void)loadAllThumbViewPhotos
{
    NSUInteger i, count = [_photoSource numberOfPhotosForPhotoGallery:self];
    for (i=0; i < count; i++) {
        
        [self loadThumbnailImageWithIndex:i];
    }
}


- (void)loadThumbnailImageWithIndex:(NSUInteger)index
{
    //NSLog(@"loadThumbnailImageWithIndex: %i", index );
    
    FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)index]];
    
    if( photo == nil )
        photo = [self createGalleryPhotoForIndex:index];
    
    [photo loadThumbnail];
}



- (void)loadFullsizeImageWithIndex:(NSUInteger)index
{
    //    NSLog(@"loadFullsizeImageWithIndex: %i", index );
    
    FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)index]];
    
    if( photo == nil )
        photo = [self createGalleryPhotoForIndex:index];
    
    [photo loadFullsize];
}



- (void)unloadFullsizeImageWithIndex:(NSUInteger)index
{
    if( index < [_photoViews count])
    {
        //    NSLog(@"unloadFullsizeImageWithIndex: %i", index);
        
        FGalleryPhoto *loader = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)index]];
        [loader unloadFullsize];
        
        FGalleryPhotoView *photoView = [_photoViews objectAtIndex:index];
        photoView.imageView.image = loader.thumbnail;
    }
}



- (FGalleryPhoto*)createGalleryPhotoForIndex:(NSUInteger)index
{
    FGalleryPhotoSourceType sourceType = [_photoSource photoGallery:self sourceTypeForPhotoAtIndex:index];
    FGalleryPhoto *photo;
    NSString *thumbPath;
    NSString *fullsizePath;
    
    if( sourceType == FGalleryPhotoSourceTypeLocal )
    {
        thumbPath = [_photoSource photoGallery:self filePathForPhotoSize:FGalleryPhotoSizeThumbnail atIndex:index];
        fullsizePath = [_photoSource photoGallery:self filePathForPhotoSize:FGalleryPhotoSizeFullsize atIndex:index];
        photo = [[FGalleryPhoto alloc] initWithThumbnailPath:thumbPath fullsizePath:fullsizePath delegate:self];
    }
    else if( sourceType == FGalleryPhotoSourceTypeNetwork )
    {
        thumbPath = [_photoSource photoGallery:self urlForPhotoSize:FGalleryPhotoSizeThumbnail atIndex:index];
        fullsizePath = [_photoSource photoGallery:self urlForPhotoSize:FGalleryPhotoSizeFullsize atIndex:index];
        photo = [[FGalleryPhoto alloc] initWithThumbnailUrl:thumbPath fullsizeUrl:fullsizePath delegate:self];
    }
    else
    {
        // invalid source type, throw an error.
        [NSException raise:@"Invalid photo source type" format:@"The specified source type of %d is invalid", sourceType];
    }
    
    //    NSLog(@"Creating new gallery photo object for index: %i", index);
    
    // assign the photo index
    photo.tag = index;
    
    // store it
    [_photoLoaders setObject:photo forKey: [NSString stringWithFormat:@"%lu", (unsigned long)index]];
    
    return photo;
}


- (void)scrollingHasEnded {
    
    //NSLog(@"En scrollingHasEnded");
    
    _isScrolling = NO;
    
    NSUInteger newIndex = floor( _scroller.contentOffset.x / _scroller.frame.size.width );
    
    // don't proceed if the user has been scrolling, but didn't really go anywhere.
    if( newIndex == _currentIndex )
        return;
    
    // clear previous
    [self unloadFullsizeImageWithIndex:_currentIndex];
    
    _currentIndex = newIndex;
    [self updateCaption];
    [self updateTitle];
    [self updateButtons];
    [self loadFullsizeImageWithIndex:_currentIndex];
    [self preloadThumbnailImages];
}


#pragma mark - FGalleryPhoto Delegate Methods


- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadThumbnailFromPath:(NSString*)path
{
    // show activity indicator for large photo view
    FGalleryPhotoView *photoView = [_photoViews objectAtIndex:photo.tag];
    [photoView.activity startAnimating];
    
    // show activity indicator for thumbail
    if( _isThumbViewShowing ) {
        FGalleryPhotoView *thumb = [_photoThumbnailViews objectAtIndex:photo.tag];
        [thumb.activity startAnimating];
    }
}

/*
 - (void)galleryPhoto:(FGalleryPhoto*)photo willLoadFullsizeFromPath:(NSString*)path
 {
 //    NSLog(@"galleryPhoto:willLoadFullsizeFromPath: %@", path );
 }
 */


- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadThumbnailFromUrl:(NSString*)url
{
    //    NSLog(@"galleryPhoto:willLoadThumbnailFromUrl:");
    
    // show activity indicator for large photo view
    FGalleryPhotoView *photoView = [_photoViews objectAtIndex:photo.tag];
    [photoView.activity startAnimating];
    
    // show activity indicator for thumbail
    if( _isThumbViewShowing ) {
        FGalleryPhotoView *thumb = [_photoThumbnailViews objectAtIndex:photo.tag];
        [thumb.activity startAnimating];
    }
}

/*
 - (void)galleryPhoto:(FGalleryPhoto*)photo willLoadFullsizeFromUrl:(NSString*)url
 {
 //    NSLog(@"galleryPhoto:willLoadFullsizeFromUrl:");
 }
 */



- (void)galleryPhoto:(FGalleryPhoto*)photo didLoadThumbnail:(UIImage*)image
{
    // grab the associated image view
    FGalleryPhotoView *photoView = [_photoViews objectAtIndex:photo.tag];
    
    // if the gallery photo hasn't loaded the fullsize yet, set the thumbnail as its image.
    if( !photo.hasFullsizeLoaded )
        photoView.imageView.image = photo.thumbnail;
    
    [photoView.activity stopAnimating];
    
    // grab the thumbail view and set its image
    FGalleryPhotoView *thumbView = [_photoThumbnailViews objectAtIndex:photo.tag];
    thumbView.imageView.image = image;
    [thumbView.activity stopAnimating];
}



- (void)galleryPhoto:(FGalleryPhoto*)photo didLoadFullsize:(UIImage*)image
{
    // only set the fullsize image if we're currently on that image
    if( _currentIndex == photo.tag )
    {
        FGalleryPhotoView *photoView = [_photoViews objectAtIndex:photo.tag];
        photoView.imageView.image = photo.fullsize;
    }
    // otherwise, we don't need to keep this image around
    else [photo unloadFullsize];
}






#pragma mark - UIScrollView Methods



- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    _isScrolling = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if( !decelerate )
    {
        [self scrollingHasEnded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollingHasEnded];
}



#pragma mark - Memory Management Methods

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    
    NSLog(@"[FGalleryViewController] didReceiveMemoryWarning! clearing out cached images...");
    // unload fullsize and thumbnail images for all our images except at the current index.
    NSArray *keys = [_photoLoaders allKeys];
    NSUInteger i, count = [keys count];
    for (i = 0; i < count; i++)
    {
        if( i != _currentIndex )
        {
            FGalleryPhoto *photo = [_photoLoaders objectForKey:[keys objectAtIndex:i]];
            [photo unloadFullsize];
            [photo unloadThumbnail];
            
            // unload main image thumb
            FGalleryPhotoView *photoView = [_photoViews objectAtIndex:i];
            photoView.imageView.image = nil;
            
            // unload thumb tile
            photoView = [_photoThumbnailViews objectAtIndex:i];
            photoView.imageView.image = nil;
        }
    }
    
    
}

/*
 - (void)viewDidUnload {
 [super viewDidUnload];
 // Release any retained subviews of the main view.
 // e.g. self.myOutlet = nil;
 }
 */

- (void)dealloc {
    
    //    NSLog(@"FGalleryViewController dealloc");
    
    // remove KVO listener
    [_container removeObserver:self forKeyPath:@"frame"];
    
    // Cancel all photo loaders in progress
    NSArray *keys = [_photoLoaders allKeys];
    NSUInteger i, count = [keys count];
    for (i = 0; i < count; i++) {
        FGalleryPhoto *photo = [_photoLoaders objectForKey:[keys objectAtIndex:i]];
        photo.delegate = nil;
        [photo unloadThumbnail];
        [photo unloadFullsize];
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    
    _photoSource = nil;
    
    _caption = nil;
    
    _captionContainer = nil;
    
    _container = nil;
    
    _innerContainer = nil;
    
    _toolbar = nil;
    
    _thumbsView = nil;
    
    _scroller = nil;
    
    [_photoLoaders removeAllObjects];
    _photoLoaders = nil;
    
    [_barItems removeAllObjects];
    _barItems = nil;
    
    [_photoThumbnailViews removeAllObjects];
    _photoThumbnailViews = nil;
    
    [_photoViews removeAllObjects];
    _photoViews = nil;
    
    _nextButton = nil;
    
    _prevButton = nil;
    
}


@end


/**
 *    This section overrides the auto-rotate methods for UINaviationController and UITabBarController
 *    to allow the tab bar to rotate only when a FGalleryController is the visible controller. Sweet.
 */

@implementation UINavigationController (FGallery)


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // see if the current controller in the stack is a gallery
    if([self.visibleViewController isKindOfClass:[FGalleryViewController class]])
    {
        FGalleryViewController *galleryController = (FGalleryViewController*)self.visibleViewController;
        [galleryController resetImageViewZoomLevels];
    }
}

@end

@implementation UITabBarController (FGallery)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if( interfaceOrientation == UIInterfaceOrientationPortrait
       || interfaceOrientation == UIInterfaceOrientationLandscapeLeft
       || interfaceOrientation == UIInterfaceOrientationLandscapeRight )
    {
        // only return yes if we're looking at the gallery
        if( [self.selectedViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navController = (UINavigationController*)self.selectedViewController;
            
            // see if the current controller in the stack is a gallery
            if([navController.visibleViewController isKindOfClass:[FGalleryViewController class]])
            {
                return YES;
            }
        }
    }
    
    // we need to support at least one type of auto-rotation we'll get warnings.
    // so, we'll just support the basic portrait.
    return ( interfaceOrientation == UIInterfaceOrientationPortrait ) ? YES : NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if([self.selectedViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navController = (UINavigationController*)self.selectedViewController;
        
        // see if the current controller in the stack is a gallery
        if([navController.visibleViewController isKindOfClass:[FGalleryViewController class]])
        {
            FGalleryViewController *galleryController = (FGalleryViewController*)navController.visibleViewController;
            [galleryController resetImageViewZoomLevels];
        }
    }
}


@end




