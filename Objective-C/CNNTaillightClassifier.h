#import "CNNTaillightClassifier.h"
#import <opencv2/opencv.hpp>
#import <TensorFlowLiteC/TensorFlowLiteC.h>

@interface CNNTaillightClassifier ()
@property(nonatomic) TFLInterpreter *interpreter;
@end

@implementation CNNTaillightClassifier

- (instancetype)initWithModelFile:(NSString *)modelFile {
    self = [super init];
    if (self) {
        NSError *error = nil;
        
        // Lade das Modell aus dem Bundle
        NSString *modelPath = [[NSBundle mainBundle] pathForResource:modelFile ofType:@"tflite"];
        if (!modelPath) {
            NSLog(@"Fehler: Modelldatei nicht gefunden.");
            return nil;
        }
        
        TFLInterpreterOptions *options = [[TFLInterpreterOptions alloc] init];
        self.interpreter = [[TFLInterpreter alloc] initWithModelPath:modelPath options:options error:&error];
        
        if (error) {
            NSLog(@"Fehler beim Initialisieren des Interpreters: %@", error.localizedDescription);
            return nil;
        }
        
        NSLog(@"Interpreter erfolgreich geladen.");
    }
    return self;
}

- (BOOL)classifyTaillight:(cv::Mat)image {
    // 1. Bild auf 28x28 skalieren
    cv::Mat resizedImage;
    cv::resize(image, resizedImage, cv::Size(28, 28), 0, 0, cv::INTER_CUBIC);
    
    // 2. Bild normalisieren
    resizedImage.convertTo(resizedImage, CV_32F, 1.0 / 127.5, -1.0);
    
    // 3. Eingabetensor vorbereiten
    NSError *error = nil;
    TFLTensor *inputTensor = [self.interpreter inputTensorAtIndex:0 error:&error];
    if (error) {
        NSLog(@"Fehler beim Abrufen des Eingabetensors: %@", error.localizedDescription);
        return NO;
    }
    
    memcpy(inputTensor.data.bytes, resizedImage.data, resizedImage.total() * resizedImage.elemSize());
    
    // 4. Inferenz ausführen
    [self.interpreter invokeWithError:&error];
    if (error) {
        NSLog(@"Fehler bei der Inferenz: %@", error.localizedDescription);
        return NO;
    }
    
    // 5. Ausgabe analysieren
    TFLTensor *outputTensor = [self.interpreter outputTensorAtIndex:0 error:&error];
    if (error) {
        NSLog(@"Fehler beim Abrufen des Ausgabetensors: %@", error.localizedDescription);
        return NO;
    }
    
    float *outputData = (float *)outputTensor.data.bytes;
    int predictedClass = outputData[0] > outputData[1] ? 0 : 1;
    
    return predictedClass == 1;
}

@end
