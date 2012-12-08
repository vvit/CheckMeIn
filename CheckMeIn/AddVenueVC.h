//
//  AddVenueVC.h
//  CheckMeIn
//
//  Created by vit on 11/12/12.
//
//

#import <UIKit/UIKit.h>
#import "BZFoursquare.h"

@interface AddVenueVC : UITableViewController <BZFoursquareRequestDelegate, UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UISearchBar *citySearchBar;
@property (weak, nonatomic) id						delegate;

@end
