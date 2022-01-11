/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that selects an image and makes a prediction using Vision and Core ML.
*/

import UIKit

class MainViewController: UIViewController {
    var firstRun = true

    /// A predictor instance that uses Vision and Core ML to generate prediction strings from a photo.
    /// 予測クラスをインスタンス化
    let imagePredictor = ImagePredictor()

    /// The largest number of predictions the main view controller displays the user.
    /// 予測結果を何個表示するかをここで決める
    let predictionsToShow = 2

    // MARK: Main storyboard outlets
    @IBOutlet weak var startupPrompts: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var backGroundImage: UIImageView!
    
    //使い方ボタンタップ
    @IBAction func useButtonTap(_ sender: Any) {
        //アラートのタイトル
        let dialog = UIAlertController(title: "使い方", message: "結果を保存しました", preferredStyle: .alert)
        //ボタンのタイトル
        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        //実際に表示させる
        self.present(dialog, animated: true, completion: nil)
    }
    
    //ロングタップ
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            //ロングタップ終了時に実行したい処理を記載する
            //コンテキスト開始
            UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0.0)
            //viewを書き出す
            self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
            // imageにコンテキストの内容を書き出す
            let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            //コンテキストを閉じる
            UIGraphicsEndImageContext()
            // imageをカメラロールに保存
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            //アラートのタイトル
            let dialog = UIAlertController(title: "Saved photo", message: "結果を保存しました", preferredStyle: .alert)
            //ボタンのタイトル
            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            //実際に表示させる
            self.present(dialog, animated: true, completion: nil)
            
        }
    }
    //@IBOutlet weak var saveImageButton: UIButton!
    
    
    ///予測結果を含めたキャプチャの保存
    /*@IBAction func saveResultImage(_ sender: Any) {
        //コンテキスト開始
        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0.0)
        //viewを書き出す
        self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
        // imageにコンテキストの内容を書き出す
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        //コンテキストを閉じる
        UIGraphicsEndImageContext()
        // imageをカメラロールに保存
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }*/
}



extension MainViewController {
    // MARK: Main storyboard actions
    /// The method the storyboard calls when the user one-finger taps the screen.
    /// １本指タップ
    @IBAction func singleTap() {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            present(photoPicker, animated: false)
            return
        }

        present(cameraPicker, animated: false)
    }

    /// The method the storyboard calls when the user two-finger taps the screen.
    /// ２本指タップ
    @IBAction func doubleTap() {
        present(photoPicker, animated: false)
    }
    
}

extension MainViewController {
    // MARK: Main storyboard updates
    /// Updates the storyboard's image view.
    /// - Parameter image: An image.
    
    func updateImage(_ image: UIImage) {
        
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }

    /// Updates the storyboard's prediction label.
    /// - Parameter message: A prediction or message string.
    /// - Tag: updatePredictionLabel
    /// 予測結果のラベルの表示
    func updatePredictionLabel(_ message: String) {
        DispatchQueue.main.async {
            self.predictionLabel.text = "\(message) "
        }

        //ラベル表示オフを解除する
        if firstRun {
            DispatchQueue.main.async {
                self.firstRun = false
                self.predictionLabel.superview?.isHidden = false
                self.startupPrompts.isHidden = true
                //self.saveImageButton.isHidden = false
            }
        }
    }
    /// Notifies the view controller when a user selects a photo in the camera picker or photo library picker.
    /// - Parameter photo: A photo from the camera or photo library.
    func userSelectedPhoto(_ photo: UIImage) {
        updateImage(photo)
        updatePredictionLabel("画像を判別中です...")

        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(photo)
        }
    }

}

extension MainViewController {
    // MARK: Image prediction methods
    /// Sends a photo to the Image Predictor to get a prediction of its content.
    /// - Parameter image: A photo.
    private func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                    completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }

    /// The method the Image Predictor calls when its image classifier model generates a prediction.
    /// - Parameter predictions: An array of predictions.
    /// - Tag: imagePredictionHandler
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            updatePredictionLabel("No predictions. (Check console log.)")
            return
        }

        let formattedPredictions = formatPredictions(predictions)

        let predictionString = formattedPredictions.joined(separator: "\n")
        updatePredictionLabel(predictionString)
    }

    /// Converts a prediction's observations into human-readable strings.
    /// - Parameter observations: The classification observations from a Vision request.
    /// - Tag: formatPredictions
    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String] {
        // Vision sorts the classifications in descending confidence order.
        let topPredictions: [String] = predictions.prefix(predictionsToShow).map { prediction in
            var name = prediction.classification

            // For classifications with more than one name, keep the one before the first comma.
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }

            return "\(prediction.confidencePercentage)%の確率で - \(name)"
        }

        return topPredictions
    }
}
