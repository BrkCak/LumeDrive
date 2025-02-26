import cv2
import numpy as np
import tensorflow as tf
from keras.models import Sequential
from keras.layers import Dense, Flatten, Dropout, Conv2D, Lambda

def normalize(x):
    return x / 127.5 - 1.0

def create_model_v1():
    model = Sequential(name="taillight-state-recognition")
    model.add(Lambda(normalize, input_shape=(28, 28, 3)))
    model.add(Conv2D(6, (5, 5), activation='relu', padding="same"))
    model.add(Conv2D(12, (5, 5), activation='relu', strides=2, padding="same"))
    model.add(Conv2D(24, (4, 4), activation='relu', strides=2, padding="same"))
    model.add(Flatten())
    model.add(Dropout(0.5))
    model.add(Dense(200, activation='relu'))
    model.add(Dense(2, activation='softmax', name="taillight_state"))

    model.compile(loss='categorical_crossentropy', optimizer='sgd', metrics=['accuracy'])
    return model


class CNNTaillightClassifier:
    def __init__(self, model_file="taillight-state-classification.h5", load_weights_only=True):
        if load_weights_only:
            self.model = create_model_v1()
            self.model.load_weights(model_file)
        else:
            from keras.models import load_model as load_keras_model
            self.model = load_keras_model(model_file, custom_objects={'normalize': normalize})

    def classify_taillight(self, img: np.ndarray) -> bool:
        img = cv2.resize(img, dsize=(28, 28), interpolation=cv2.INTER_CUBIC)
        img = np.expand_dims(img, axis=0)
        result = self.model.predict(img)
        return np.argmax(result) == 1


def convert_to_tflite(h5_model_path, tflite_model_path):
    model = tf.keras.models.load_model(h5_model_path, custom_objects={'normalize': normalize})

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    with open(tflite_model_path, "wb") as f:
        f.write(tflite_model)
    print(f"Modell wurde erfolgreich nach {tflite_model_path} konvertiert.")


if __name__ == "__main__":
    h5_model_path = "taillight-state-classification.h5"
    tflite_model_path = "taillight-state-classification.tflite"

    convert_to_tflite(h5_model_path, tflite_model_path)
