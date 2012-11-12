//
//  VenuesVC.m
//  FSQDemo
//
//  Created by vit on 11/12/12.
//
//

#import "VenuesVC.h"
#import "AddVenueVC.h"

@interface VenuesVC ()
@property (strong, nonatomic) NSMutableArray	*venues;
@end

@implementation VenuesVC

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
	{
		//try to restore
		NSArray *readOnly = [[NSUserDefaults standardUserDefaults] objectForKey:@"venues"];
		if (readOnly)
		{
			self.venues = [NSMutableArray arrayWithArray:readOnly];
		}
		else
		{
			self.venues = [NSMutableArray array];

//			[_venues addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Kronverk Cinema",  @"name", @"4c1ce525eac020a1333347c2", @"id", nil]];
//			[_venues addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Palladium Cinema", @"name", @"4fc08da1e4b0bb07321b63f8", @"id", nil]];
//			[_venues addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Coffee Life (Dafi)", @"name", @"4d8f46f7c479a35d66735897", @"id", nil]];
			
			//save
//			[[NSUserDefaults standardUserDefaults] setObject:_venues forKey:@"venues"];
//			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _venues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VenueCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell
	NSDictionary *dict = _venues[indexPath.row];
	cell.textLabel.text = [dict objectForKey:@"name"];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		[_venues removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		//save
		[[NSUserDefaults standardUserDefaults] setObject:_venues forKey:@"venues"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *dict = _venues[indexPath.row];

	//save selection
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:_venue1 ? @"selectedVenue1" : @"selectedVenue2"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	//inform the delegate
	if ([_delegate respondsToSelector:_venue1 ? @selector(venue1Selected:) : @selector(venue2Selected:)])
	{
		if (_venue1)
			[_delegate performSelector:@selector(venue1Selected:) withObject:dict];
		else
			[_delegate performSelector:@selector(venue2Selected:) withObject:dict];
	}

	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	UINavigationController *parentVC = (UINavigationController*)segue.destinationViewController;
	AddVenueVC *vc = (AddVenueVC*)parentVC.viewControllers[0];
	vc.delegate = self;
}

- (void)venueAdded:(NSDictionary*)venue
{
	[_venues addObject:venue];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_venues.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	
	//save
	[[NSUserDefaults standardUserDefaults] setObject:_venues forKey:@"venues"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
