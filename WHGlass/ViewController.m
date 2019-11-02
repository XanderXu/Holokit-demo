//
//  ViewController.m
//  WHGlass
//
//  Created by CoderXu on 2019/10/15.
//  Copyright © 2019 XanderXu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;//AR 视图带背景视频
@property (nonatomic, strong) SCNNode *shipNode;//AR 中的模型

@property (weak, nonatomic) IBOutlet SCNView *leftView;//左眼视图，黑色背景
@property (weak, nonatomic) IBOutlet SCNView *rightView;//右眼视图，黑色背景

@property (nonatomic, strong) SCNNode *headNode;//代表头部（手机）
@property (nonatomic, strong) SCNNode *leftCameraNode;//左眼相机所在的Node
@property (nonatomic, strong) SCNNode *rightCameraNode;//右眼相机所在的 Node
@property (nonatomic, strong) SCNScene *sceneForEyes;//双目的场景，黑色背景
@property (nonatomic, strong) SCNNode *shipNodeForEyes;//双目的模型
@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackGround) name:UIApplicationWillResignActiveNotification object:nil];
    [self setupScene];
    [self setupSceneViews];

}

- (void)setupScene {
    // 双目场景
    self.sceneForEyes = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    self.shipNodeForEyes = [self.sceneForEyes.rootNode childNodeWithName:@"ship" recursively:YES];
    
    // 双目场景中代表头部的 Node
    SCNNode *headNode = [SCNNode node];
    self.headNode = headNode;
    [self.sceneForEyes.rootNode addChildNode:headNode];
    
    // 添加两个相机，对应左右眼视图
    SCNNode *leftCameraNode = [SCNNode node];
    self.leftCameraNode = leftCameraNode;
    leftCameraNode.camera = [SCNCamera camera];
    leftCameraNode.camera.zNear = 0;
    leftCameraNode.camera.zFar = 1000;
    leftCameraNode.camera.fieldOfView = 36;//保证双目视频看到的大小和 AR 中的一样大
    [headNode addChildNode:leftCameraNode];
    leftCameraNode.position = SCNVector3Make(-0.03, 0, 0);//左眼在头部的位置
    
    SCNNode *rightCameraNode = [SCNNode node];
    self.rightCameraNode = rightCameraNode;
    rightCameraNode.camera = [SCNCamera camera];
    rightCameraNode.camera.zNear = 0;
    rightCameraNode.camera.zFar = 1000;
    rightCameraNode.camera.fieldOfView = 36;//保证双目视频看到的大小和 AR 中的一样大
    [headNode addChildNode:rightCameraNode];
    rightCameraNode.position = SCNVector3Make(0.03, 0, 0);//右眼在头部的位置
    
    headNode.position = SCNVector3Make(0, 0, 0);
    
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    [self.sceneForEyes.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [self.sceneForEyes.rootNode addChildNode:ambientLightNode];
    
}
- (void)setupSceneViews {
    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin | ARSCNDebugOptionShowFeaturePoints;
    // AR Scene 带背景视频
    self.sceneView.scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    self.shipNode = [self.sceneView.scene.rootNode childNodeWithName:@"ship" recursively:YES];
    
    // 锚点的位置，放在 z 轴负 0.5 米处
    simd_float4x4 trans = simd_diagonal_matrix(simd_make_float4(1,1,1,1));
    trans.columns[3][2] -= 0.5;
    
    ARAnchor *anchor = [[ARAnchor alloc] initWithName:@"base" transform:trans];
    [self.sceneView.session addAnchor:anchor];
    
    self.shipNode.simdTransform = simd_mul(self.shipNode.simdTransform, anchor.transform);
    self.shipNodeForEyes.simdTransform = self.shipNode.simdTransform;
    
    // 相对结点，代表 AR 中的眼睛相对于手机的位置
    SCNNode *relativeCamreaNode = [SCNNode node];
    relativeCamreaNode.position = SCNVector3Make(0, 0.08, -0.13);//手机在脑袋顶上，画面经过光学放大
    [self.sceneView.pointOfView addChildNode:relativeCamreaNode];
    
    // retrieve the SCNView
    SCNView *leftView = self.leftView;
    leftView.playing = YES;
    // set the scene to the view
    leftView.scene = self.sceneForEyes;
    
    // 左视图与左相机关联
    leftView.pointOfView = self.leftCameraNode;
    // show statistics such as fps and timing information
    leftView.showsStatistics = YES;
    // configure the view
    leftView.backgroundColor = [UIColor blackColor];
    
    
    // retrieve the SCNView
    SCNView *rightView = self.rightView;
    rightView.playing = YES;
    // set the scene to the view
    rightView.scene = self.sceneForEyes;
    
    
    // 右视图与右相机关联
    rightView.pointOfView = self.rightCameraNode;
    // show statistics such as fps and timing information
    rightView.showsStatistics = YES;
    // configure the view
    rightView.backgroundColor = [UIColor blackColor];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIScreen mainScreen] setBrightness: 1];
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIScreen mainScreen] setBrightness: 0.5];
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)enterBackGround {
    [self.sceneView.session pause];
    [[UIScreen mainScreen] setBrightness: 0.5];
}


#pragma mark - ARSCNViewDelegate
// Override to create and configure nodes for anchors added to the view's session.
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    if ([anchor.name isEqualToString:@"base"]) {
        return self.shipNode;
    }
    return nil;
}

-(void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    if ([anchor.name isEqualToString:@"base"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.shipNodeForEyes.simdTransform = node.simdTransform;
            
        });
    }
}

- (void)renderer:(id <SCNSceneRenderer>)renderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.headNode.simdTransform = renderer.pointOfView.childNodes.firstObject.simdWorldTransform;
            
    });
}
- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

@end
