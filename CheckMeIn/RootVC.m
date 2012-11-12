/*
 * Copyright (C) 2011 Ba-Z Communication Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "FSQJSONObjectViewController.h"
#import "RootVC.h"
#import "VenuesVC.h"


#define kClientID       FOURSQUARE_CLIENT_ID
#define kCallbackURL    FOURSQUARE_CALLBACK_URL

@interface RootVC ()
@property(nonatomic,strong) BZFoursquareRequest		*request;
@property(nonatomic,copy) NSDictionary				*meta;
@property(nonatomic,copy) NSArray					*notifications;
@property(nonatomic,copy) NSDictionary				*response;
@property (strong, nonatomic)	NSDictionary		*venue1, *venue2;
@end

enum {
    kAuthenticationSection = 0,
	kSetupSection,
    kResponsesSection,
    kSectionCount
};

enum {
    kAccessTokenRow = 0,
    kAuthenticationRowCount
};

enum {
    kSetupVenue1 = 0,
    kSetupVenue2,
	kSetupCheckinCount,
	kSetupTimeout,
	kSetupPublic,
	kSetupCheckin,
    kSetupRowCount
};

enum {
    kMetaRow = 0,
    kNotificationsRow,
    kResponseRow,
    kResponsesRowCount
};

@implementation RootVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
	{
        self.foursquare = [[BZFoursquare alloc] initWithClientID:kClientID callbackURL:kCallbackURL];
        _foursquare.version = @"20111119";
        _foursquare.locale = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
        _foursquare.sessionDelegate = self;
		
		//restore token
		NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
		if (token.length)
			_foursquare.accessToken = token;
		
		//restore selection
		self.venue1 = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectedVenue1"];
		self.venue2 = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectedVenue2"];
    }
    return self;
}

- (void)dealloc
{
    _foursquare.sessionDelegate = nil;
    [self cancelRequest];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];

}

- (void)viewDidUnload
{
	[self setCountlabel:nil];
	[self setTimeoutLabel:nil];
	[self setCheckinCountSlider:nil];
	[self setTimeoutSlider:nil];
	[self setPublicSwitch:nil];
	[super viewDidUnload];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
	{
		case kAuthenticationSection:
			if (![_foursquare isSessionValid])
				cell.textLabel.text = NSLocalizedString(@"Obtain Access Token", @"");
			else
				cell.textLabel.text = NSLocalizedString(@"Forget Access Token", @"");
			break;
		
		case kSetupSection:
			if (indexPath.row == 0)
			{
				if ([_venue1 objectForKey:@"name"] && [_venue1 objectForKey:@"id"])
					cell.detailTextLabel.text = [_venue1 objectForKey:@"name"];
			}
			else if (indexPath.row == 1)
			{
				if ([_venue2 objectForKey:@"name"] && [_venue2 objectForKey:@"id"])
					cell.detailTextLabel.text = [_venue2 objectForKey:@"name"];
			}
			break;
			
		case kResponsesSection:
        {
            id collection = nil;
            switch (indexPath.row)
			{
				case kMetaRow:
					collection = _meta;
					break;
				case kNotificationsRow:
					collection = _notifications;
					break;
				case kResponseRow:
					collection = _response;
					break;
            }
			
            if (!collection)
			{
                cell.textLabel.enabled = NO;
                cell.detailTextLabel.text = nil;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
			else
			{
                cell.textLabel.enabled = YES;
                NSUInteger count = [collection count];
                NSString *format = (count == 1) ? NSLocalizedString(@"(%lu item)", @"") : NSLocalizedString(@"(%lu items)", @"");
                cell.detailTextLabel.text = [NSString stringWithFormat:format, count];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
        }
        break;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return (cell.selectionStyle == UITableViewCellSelectionStyleNone) ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
	{
		case kAuthenticationSection:
			
			if (![_foursquare isSessionValid])
			{
				[_foursquare startAuthorization];
			}
			else
			{
				[_foursquare invalidateSession];
				
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accessToken"];
				[[NSUserDefaults standardUserDefaults] synchronize];
				
				NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
				[tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
				[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			}
		
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
    
		case kSetupSection:
			switch (indexPath.row)
			{
				case kSetupVenue1:
					break;
				case kSetupVenue2:
					break;
				case kSetupCheckinCount:
					break;
				case kSetupTimeout:
					break;
				case kSetupCheckin:
					[self checkin];
					break;
				default:
					break;
			}
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
			
		case kResponsesSection:
		{
			id JSONObject = nil;
			switch (indexPath.row) {
			case kMetaRow:
				JSONObject = _meta;
				break;
			case kNotificationsRow:
				JSONObject = _notifications;
				break;
			case kResponseRow:
				JSONObject = _response;
				break;
			}
			FSQJSONObjectViewController *JSONObjectViewController = [[FSQJSONObjectViewController alloc] initWithJSONObject:JSONObject];
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			JSONObjectViewController.title = cell.textLabel.text;
			[self.navigationController pushViewController:JSONObjectViewController animated:YES];
		}
		break;
    }
}

#pragma mark - Actions

- (void)checkin
{
	//save
	checkinCount	= _checkinCountSlider.value;
	timeoutSeconds	= _timeoutSlider.value;
	publicCheckin	= [_publicSwitch isOn];
	
	//reset
	checkinsMade = 0;
	
    [self prepareForRequest];
	
	//show activity indicator
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self showHUD];
	
	[self doRequest];
}

- (void)doRequest
{
	NSLog(@"Checking: %@ (%d)", (checkinsMade % 2 == 0) ? [_venue1 objectForKey:@"id"] : [_venue2 objectForKey:@"id"], checkinsMade+1);
	
	NSString *venueID = nil;

	//venue2 available?
	if ([[_venue2 objectForKey:@"id"] length])
		venueID = (checkinsMade % 2 == 0) ? [_venue1 objectForKey:@"id"] : [_venue2 objectForKey:@"id"];
	else
		venueID = [_venue1 objectForKey:@"id"];
	
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:venueID, @"venueId", publicCheckin ? @"public" : @"private", @"broadcast", nil];
	self.request = [_foursquare requestWithPath:@"checkins/add" HTTPMethod:@"POST" parameters:parameters delegate:self];
	[_request start];
}

- (IBAction)countSliderChanged:(UISlider *)sender
{
	if (![sender isKindOfClass:[UISlider class]])
		return;
	
	_countlabel.text = [NSString stringWithFormat:@"Checkin Count (%.0f):", sender.value];
}

- (IBAction)timeoutSliderChanged:(UISlider *)sender
{
	if (![sender isKindOfClass:[UISlider class]])
		return;
	
	_timeoutLabel.text = [NSString stringWithFormat:@"Timeout, sec (%.0f):", sender.value];
}

#pragma mark - BZFoursquareRequestDelegate

- (void)requestDidFinishLoading:(BZFoursquareRequest *)request
{
	NSLog(@"Checked : %@ (%d)", (checkinsMade % 2 == 0) ? [_venue1 objectForKey:@"id"] : [_venue2 objectForKey:@"id"], checkinsMade+1);
	
	for (NSDictionary *dict in request.notifications)
	{
		if ([[dict objectForKey:@"type"] isEqualToString:@"message"])
		{
			NSLog(@"%@", [[dict objectForKey:@"item"] objectForKey:@"message"]);
		}
		
		if ([[dict objectForKey:@"type"] isEqualToString:@"mayorship"])
		{
			NSLog(@"%@", [[dict objectForKey:@"item"] objectForKey:@"message"]);
		}
	}
	
	//in progress
	if (checkinsMade < checkinCount-1)
	{
		self.request = nil;
		
		//update progress view
		dispatch_async(dispatch_get_main_queue(), ^{
			HUD.progress = ((checkinsMade*100.0f)/checkinCount) / 100.0f;
		});
		
		checkinsMade++;
		
		//next request
		[self performSelector:@selector(doRequest) withObject:nil afterDelay:10.0 + ((checkinsMade%10==0) ? 10 : 0)];
	}
	else	//done
	{
		self.meta = request.meta;
		self.notifications = request.notifications;
		self.response = request.response;
		self.request = nil;
		
		[self updateView];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		
		//update progress view
		dispatch_async(dispatch_get_main_queue(), ^{
			HUD.progress = 1.0;
			HUD.taskInProgress = NO;
			[HUD hide:YES];
		});
	}
}

- (void)request:(BZFoursquareRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[[error userInfo] objectForKey:@"errorDetail"] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alertView show];

    self.meta = request.meta;
    self.notifications = request.notifications;
    self.response = request.response;
    self.request = nil;
    [self updateView];
	
	//update progress view
	dispatch_async(dispatch_get_main_queue(), ^{
		HUD.progress = 1.0;
		HUD.taskInProgress = NO;
		[HUD hide:YES];
	});
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - BZFoursquareSessionDelegate

- (void)foursquareDidAuthorize:(BZFoursquare *)foursquare
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:kAccessTokenRow inSection:kAuthenticationSection];
    NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
	
	//save as user default
	[[NSUserDefaults standardUserDefaults] setObject:foursquare.accessToken forKey:@"accessToken"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	NSLog(@"%@", foursquare.accessToken);
}

- (void)foursquareDidNotAuthorize:(BZFoursquare *)foursquare error:(NSDictionary *)errorInfo
{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, errorInfo);
}

#pragma mark - Misc

- (void)updateView
{
    if ([self isViewLoaded])
	{
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView reloadData];
        if (indexPath) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (void)cancelRequest
{
    if (_request)
	{
        _request.delegate = nil;
        [_request cancel];
        self.request = nil;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

- (void)prepareForRequest
{
    [self cancelRequest];
    self.meta = nil;
    self.notifications = nil;
    self.response = nil;
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	VenuesVC *vc = (VenuesVC*)segue.destinationViewController;
	vc.delegate = self;
	vc.venue1 = [segue.identifier isEqualToString:@"Venue1Segue"];
}

- (void)venue1Selected:(NSDictionary*)venue
{
	self.venue1 = venue;
	[self.tableView reloadData];
}

- (void)venue2Selected:(NSDictionary*)venue
{
	self.venue2 = venue;
	[self.tableView reloadData];
}

#pragma mark - HUD

- (void)showHUD
{
	HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	// Set determinate mode
	HUD.mode = MBProgressHUDModeDeterminate;
	HUD.labelText = @"Checking In...";
	
	HUD.taskInProgress = YES;
	HUD.progress = 0.0;
	[HUD show:YES];
}

@end
