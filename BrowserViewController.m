#import "BrowserViewController.h"
#import "GIFViewController.h"

@interface BrowserViewController ()
@property (nonatomic, copy) NSString *directory;
@property (nonatomic, retain) NSArray *entries;
@end

@implementation BrowserViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _directory = [@"/var/mobile/Media" copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Giffy";
    self.navigationItem.prompt = @"Browse folders and tap a GIF to play";
    [self reloadEntries];
}

- (void)reloadEntries {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *names = [fm contentsOfDirectoryAtPath:self.directory error:&error];
    NSMutableArray *items = [NSMutableArray array];
    for (NSString *name in names) {
        if ([name hasPrefix:@"."]) continue;
        NSString *path = [self.directory stringByAppendingPathComponent:name];
        BOOL isDirectory = NO;
        if (![fm fileExistsAtPath:path isDirectory:&isDirectory]) continue;
        if (isDirectory || [[path.pathExtension lowercaseString] isEqualToString:@"gif"])
            [items addObject:@{@"name": name, @"path": path, @"directory": @(isDirectory)}];
    }
    [items sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        BOOL ad = [a[@"directory"] boolValue], bd = [b[@"directory"] boolValue];
        if (ad != bd) return ad ? NSOrderedAscending : NSOrderedDescending;
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
    self.entries = items;
    self.navigationItem.leftBarButtonItem = nil;
    if (![self.directory isEqualToString:@"/var/mobile/Media"]) {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Media" style:UIBarButtonItemStyleBordered target:self action:@selector(goToMedia)] autorelease];
    }
    if (error && !names) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Can't open folder" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
    }
    [self.tableView reloadData];
}

- (void)goToMedia {
    self.directory = @"/var/mobile/Media";
    self.title = @"Giffy";
    [self reloadEntries];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.entries.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"FileCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    NSDictionary *item = self.entries[indexPath.row];
    cell.textLabel.text = item[@"name"];
    cell.accessoryType = [item[@"directory"] boolValue] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.imageView.image = [UIImage imageNamed:[item[@"directory"] boolValue] ? @"folder" : @"photo"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = self.entries[indexPath.row];
    if ([item[@"directory"] boolValue]) {
        self.directory = item[@"path"];
        self.title = item[@"name"];
        [self reloadEntries];
    } else {
        GIFViewController *viewer = [[[GIFViewController alloc] initWithPath:item[@"path"]] autorelease];
        [self.navigationController pushViewController:viewer animated:YES];
    }
}
@end
