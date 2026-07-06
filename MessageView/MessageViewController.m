//
//  MessageViewController.m
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "MessageViewController.h"
#import "GlobalRouter.h"
#import "MessageViewPresenter.h"
#import "CommonProcs.h"

@interface MessageViewController ()

@end

@implementation MessageViewController

@synthesize currentMessage, topTextConstraint, presenter, scroll, text, subjLabel,textWidthConstraint, textHeightConstraint;
@synthesize viewInScroll, attScrollWidthConstraint;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //[self updateMessageView];
    
    //scroll.translatesAutoresizingMaskIntoConstraints  = NO;
    //viewInScroll.translatesAutoresizingMaskIntoConstraints = NO;
    
    /*
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    UIView *contentView;
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
    [scroll addSubview:contentView];
    
    // DON'T change contentView's translatesAutoresizingMaskIntoConstraints,
    // which defaults to YES;
    
    // Set the content size of the scroll view to match the size of the content view:
    [scroll setContentSize:CGSizeMake(screenWidth,screenHeight)];
    
    */
    /*
    [viewInScroll setFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    
    scroll.contentSize = CGSizeMake(self.view.frame.size.width, screenHeight>screenWidth?screenHeight:screenWidth);
    
    CGSize sz = [viewInScroll systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    [viewInScroll setFrame:CGRectMake(0, 0, sz.width, sz.height)];
    [scroll setContentSize:sz];
     
     */
    
    self.navigationController.toolbarHidden = NO;
}

- (void)viewDidLayoutSubviews {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.subjLabel.preferredMaxLayoutWidth = self.view.frame.size.width-120;
        
        //textHeightConstraint.constant = text.contentSize.height;
        [self webViewDidFinishLoad:self.text];
        textWidthConstraint.constant = self.view.frame.size.width-30;
        attScrollWidthConstraint.constant = self.view.frame.size.width-30;
    });
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    [self adjustWebView];
    //NSLog(@"size: %f, %f", fittingSize.width, fittingSize.height);
}

-(void)adjustWebView
{
    CGRect frame = text.frame;
    //frame.size.height = 1;
    //text.frame = frame;
    //CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGSize fittingSize = [text sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    //frame.size.width = screenRect.size.width;
    text.frame = frame;
    
    CGSize sz = CGSizeMake(fittingSize.width, fittingSize.height+text.frame.origin.y+10);
    [scroll setContentSize:sz];
}

-(void)updateMessageView
{
    if (currentMessage == nil) {
        currentMessage = [[FullMessageEntity alloc] init];
        //return;
    }
    
    UILabel *fromLbl = (UILabel *)[self.view viewWithTag:1];
    [fromLbl setText:currentMessage.fromName];
    
    UILabel *fromAddrLbl = (UILabel *)[self.view viewWithTag:2];
    [fromAddrLbl setText:currentMessage.fromAddress];
    
    UILabel *dateLbl = (UILabel *)[self.view viewWithTag:3];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"dd.MM.YY HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:currentMessage.date];
    [dateLbl setText:dateString];
    
    UILabel *subjLbl = (UILabel *)[self.view viewWithTag:4];
    [subjLbl setText:currentMessage.subject];
    //[subjLbl sizeToFit];
    
    //UILabel* subj = (UILabel*)[self.view viewWithTag:4];
    //CGFloat hgt = subj.frame.size.height;
    
    UIButton *star = (UIButton*)[self.view viewWithTag:5];
    if (currentMessage.flags & mfFavourite) {
        [star setImage:[UIImage imageNamed:@"starYellow"] forState:UIControlStateNormal];
    }else{
        UIImage* strL = [UIImage imageNamed:@"starLight"];
        [star setImage:strL forState:UIControlStateNormal];
    }
    
    //[text setText:currentMessage.messageBody];
    NSString* body = currentMessage.messageBody;
    
    if(body != nil){
        if (currentMessage.encType != enTypeNone) {
            // Set font since it's a plaintext and the font is shit
            body = [NSString stringWithFormat:@"<span style=\"font-family: %@; font-size: %i\">%@</span>",
                          @"Helvetica",
                          14,
                          body];
            
        }
    }
    
    //NSAttributedString* body2 = [[NSAttributedString alloc] initWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];
    [text loadHTMLString:body baseURL:nil];
    
    UIScrollView* attScroll = (UIScrollView*)[self.view viewWithTag:10];
    
    //attScroll.subviews
    NSArray *viewsToRemove = [attScroll subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    
    if(currentMessage.attachments.count == 0){
        [self setAttachmentStripVisible:NO :NO];
        [self toggleAttachmentButtonHidden:YES];
    }else{
        //int index = 0;
        [self setAttachmentStripVisible:YES :NO];
        [self toggleAttachmentButtonHidden:NO];
        UILabel *attLabel = (UILabel *)[self.view viewWithTag:12];
        attLabel.text = [NSString stringWithFormat:@"(%lu)", (unsigned long)currentMessage.attachments.count];
        
        NSArray* attViews = [CommonProcs showAttachmentsIcons:currentMessage scroll:attScroll];
        for (UIImageView* att in attViews) {
            // Add action
            [att setUserInteractionEnabled:YES];
            UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAttachment:)];
            [singleTap setNumberOfTapsRequired:1];
            [att addGestureRecognizer:singleTap];
        }
        
        /*
        for (UIImage* im in currentMessage.attachments) {
            
            // Create thumbnail image
            CGSize destinationSize = CGSizeMake(70, 70);
            
            UIGraphicsBeginImageContext(destinationSize);
            [im drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            UIImageView* att = [[UIImageView alloc] initWithImage:newImage];
            att.tag = index;
            CGRect frameRect = att.frame;
            // Add a 72x72 image view for attachment
            frameRect.origin = CGPointMake(index*78, 0);
            frameRect.size = CGSizeMake(72, 72);
            att.frame = frameRect;
            att.contentMode = UIViewContentModeScaleToFill;
            
            // Add action
            [att setUserInteractionEnabled:YES];
            UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAttachment:)];
            [singleTap setNumberOfTapsRequired:1];
            [att addGestureRecognizer:singleTap];
            
            
            [attScroll addSubview:att];
            index++;
        }
        [attScroll setContentSize:CGSizeMake(80*index,72)]; // set scroll inner size to enable scrolling
         
        */
    }
    
    // this message contains a certificate, save it
    if (currentMessage.encType == enTypePasswordForCert) {
        // do it in presenter before showing message
    }
    //NSLog(@"View is %fx%f",self.view.frame.size.width, self.view.frame.size.height);
    
    
    CGSize sz = [viewInScroll systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    [scroll setContentSize:sz];
    
    //NSLog(@"Scroll view is %fx%f",self.scroll.frame.size.width, self.scroll.frame.size.height);
    //NSLog(@"Text view is %fx%f",self.text.frame.size.width, self.text.frame.size.height);
}

-(void)showAttachment:(UIGestureRecognizer *)recognizer
{
    //NSLog(@"image click at %li", (long)[recognizer view].tag);
    //[[[GlobalRouter sharedManager] getMessageRouter]wantShowAttachment:currentMessage.attachments[[recognizer view].tag]];
    [presenter wantShowAttachment:currentMessage.attachments[[recognizer view].tag-1000]];
}

-(IBAction)saveAllAttachments:(id)sender
{
    if([presenter wantSaveAll:currentMessage])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Attachments saved",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)done:(id)sender
{
    [[[GlobalRouter sharedManager] getMessageRouter] finished];
}

-(void)toggleAttachmentButtonHidden:(BOOL)hidden
{
    UIButton* attButton = (UIButton*)[self.view viewWithTag:11];
    UILabel *attLabel = (UILabel *)[self.view viewWithTag:12];
    UIButton* saveButton = (UIButton*)[self.view viewWithTag:13];
    
    attButton.hidden = hidden;
    attLabel.hidden = hidden;
    saveButton.hidden = hidden;
}

-(IBAction)toggleAttachmentStrip:(id)sender
{
    [self setAttachmentStripVisible:NO :YES];
}

-(void)setAttachmentStripVisible:(BOOL)visible :(BOOL)invert
{
    UIScrollView* attScroll = (UIScrollView*)[self.view viewWithTag:10];
    UITextView* text0 = (UITextView*)[self.view viewWithTag:21];
    
    /*
    CGRect frameRect = attScroll.frame;
    CGRect frameRect2 = text0.frame;
    int newHeight = 0;
    int subjHeight = subj.frame.size.height;
    
    if(!invert){
        if(frameRect2.origin.y < frameRect.origin.y && !visible)
            return;
        else if(frameRect2.origin.y > frameRect.origin.y && visible)
            return;
    }
    
    if(frameRect2.origin.y < frameRect.origin.y){
        newHeight = -(attScroll.frame.size.height+2);
    }else{
        newHeight = attScroll.frame.size.height+2;//87;
    }
     
     */
    //topTextConstraint.constant = newHeight;
    
    if (invert && topTextConstraint.constant == 0) {
        topTextConstraint.constant = attScroll.frame.size.height;
    }else if (invert && topTextConstraint.constant > 1){
        topTextConstraint.constant = 0;
    }else{
        topTextConstraint.constant = visible?attScroll.frame.size.height:0;
    }
    [text0 updateConstraints];
}

-(IBAction)wantReplyToMessage:(id)sender
{
    [presenter wantReplyToMessage:currentMessage];
}

-(IBAction)wantForwardMessage:(id)sender
{
    [presenter wantForwardMessage:currentMessage];
}

-(IBAction)wantMarkMessage:(id)sender
{
    [presenter wantMarkMessage:currentMessage];
    
    UIButton *star = (UIButton*)[self.view viewWithTag:5];
    if (currentMessage.flags & mfFavourite) {
        [star setImage:[UIImage imageNamed:@"starYellow"] forState:UIControlStateNormal];
    }else{
        [star setImage:[UIImage imageNamed:@"starLight"] forState:UIControlStateNormal];
    }
}

-(IBAction)wantDeleteMessage:(id)sender
{
    [presenter wantDeleteMessage:currentMessage];
}


-(void)showError:(NSString*)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
    alert.tag = 10000;
    [alert show];
}

-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:alertText delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
    alert.tag = 101;
    alertBlock = block;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101)
    {
        if (buttonIndex == 0)
        {
        
        }else{
            alertBlock();
        }
    }
}

-(IBAction)addContact:(id)sender
{
    [self.presenter wantToAddContactFor:currentMessage.fromName address:currentMessage.fromAddress];
}


/*
-(void)wantShowAttachment:(UIImage*)attachment
{
    [presenter wantShowAttachment:attachment];
}
 
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
