//
//  ChooseLocationController.m
//  Flawk
//
//  Created by Justin Brower on 3/9/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "ChooseLocationController.h"
#import "API.h"
#import "LocationCell.h"

@implementation ChooseLocationController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LocationCell *cell = (LocationCell *)[tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
    
    if (cell == nil) {
        cell = [[LocationCell alloc] init];
    }
    
    [cell applyLocation:[[API sharedAPI] locationChoices][indexPath.row]];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[API sharedAPI] locationChoices].count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *venue = [[API sharedAPI] locationChoices][indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationChosen" object:nil userInfo:venue];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [[[self navigationItem] leftBarButtonItem] setTintColor:[UIColor whiteColor]];
    [super viewDidLoad];
}

@end
