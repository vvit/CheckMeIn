//
//  AddVenueVC.m
//  CheckMeIn
//
//  Created by vit on 11/12/12.
//
//

#import "AddVenueVC.h"
#import "AppDelegate.h"

@interface AddVenueVC ()
@property (strong, nonatomic) NSArray	*dataSource;
@end

@implementation AddVenueVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
	[self setSearchBar:nil];
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[_searchBar becomeFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VenueCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell
	NSDictionary *dict = _dataSource[indexPath.row];
	
	cell.textLabel.text = [dict objectForKey:@"name"];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [[dict objectForKey:@"location"] objectForKey:@"address"]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *dict = _dataSource[indexPath.row];

	//inform the delegate
	if ([_delegate respondsToSelector:@selector(venueAdded:)])
		[_delegate performSelector:@selector(venueAdded:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dict objectForKey:@"name"], @"name", [dict objectForKey:@"id"], @"id", nil]];
	
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark - Misc

- (void)search:(NSString*)searchTerm
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	AppDelegate *del = [UIApplication sharedApplication].delegate;
	
	NSDictionary		*parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"Kharkiv, Ukraine", @"near", [NSNumber numberWithInt:50], @"limit", searchTerm, @"query", nil];
	BZFoursquareRequest *request = [[del foursquareObject] requestWithPath:@"venues/search" HTTPMethod:@"GET" parameters:parameters delegate:self];
	
	[request start];
}

- (IBAction)cancelTap:(id)sender
{
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark - BZFoursquareRequestDelegate

- (void)requestDidFinishLoading:(BZFoursquareRequest *)request
{
	self.dataSource = [request.response objectForKey:@"venues"];
	[self.tableView reloadData];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)request:(BZFoursquareRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[[error userInfo] objectForKey:@"errorDetail"] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alertView show];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self search:searchBar.text];
	[searchBar resignFirstResponder];
}

@end
