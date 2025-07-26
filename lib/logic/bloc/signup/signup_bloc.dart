import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:linkup/data/data_parser/signup_page/data_parser.dart';
import 'package:linkup/data/enums/message_type_enum.dart';
import 'package:linkup/data/http_services/common_http_services/common_http_services.dart';
import 'package:linkup/presentation/constants/singup_page/flow.dart';
import 'package:meta/meta.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  late SignUpPageFlow _signUpPageFlow;
  int _currentIndex = 0;
  int _progressBarIndex = 0;

  SignupBloc() : super(SignupInitial(currentIndex: 0, progessBarIndex: 0)) {
    on<SignupInit>((event, emit) async {
      _signUpPageFlow = event.signUpPageFlow;
      _currentIndex = event.currentIndex;

      add(SignupNext(isAtEnd: _currentIndex == _signUpPageFlow.flow.length - 1));
    });

    on<SignupNext>((event, emit) async {
      print(_currentIndex);
      if (_currentIndex == 9) {
        await _uploadPhotos(emit);
        return;
      }

      _currentIndex++;
      if (_signUpPageFlow.flow[_currentIndex]["showProgressBar"] == null) {
        _progressBarIndex = _signUpPageFlow.flow[_currentIndex]["index"];
      }

      if (_currentIndex > 11 && !event.isAtEnd) {
        emit(SignupInitial(buttonText: "Skip", currentIndex: _currentIndex, progessBarIndex: _progressBarIndex));
      } else if (_currentIndex == 9) {
        emit(SignupInitial(buttonText: "Upload Photos", currentIndex: _currentIndex, progessBarIndex: _progressBarIndex));
      } else {
        emit(SignupInitial(buttonText: event.isAtEnd ? "Finish" : "Next", currentIndex: _currentIndex, progessBarIndex: _progressBarIndex));
      }
    });
  }

  Future<void> _uploadPhotos(Emitter<SignupState> emit) async {
    if (SignUpDataParser.data.photos != null && SignUpDataParser.data.photos!.isNotEmpty) {
      emit(SingupPhotoUploading());

      try {
        // Upload first user photo and retrieve user pfp from here
        final firstImageDataRes = await CommonHttpServices().uploadPfp(
          file: File(SignUpDataParser.data.photos![0].path),
          mediaType: MessageType.image,
        );

        print(firstImageDataRes);

        if (firstImageDataRes['status'] != 'failed') {
          final futures =
              SignUpDataParser.data.photos!.asMap().entries.where((entry) => entry.key != 0).map((entry) async {
                final photo = entry.value;
                final result = await CommonHttpServices().uploadMediaUser(file: File(photo.path), mediaType: MessageType.image);
                return result['metadata']['signed_url'] as String;
              }).toList();

          List<String> uploadedUrls = await Future.wait(futures);
          uploadedUrls.insert(0, firstImageDataRes["original_image_url"]);
          SignUpDataParser.updateField(photos: uploadedUrls);
          SignUpDataParser.updateField(profilePicture: firstImageDataRes['profile_picture_url']);

          print('Photos uploaded');

          emit(SingupPhotoUploaded());

          // Now increment index and emit new state
          _currentIndex++;
          if (_signUpPageFlow.flow[_currentIndex]["showProgressBar"] == null) {
            _progressBarIndex = _signUpPageFlow.flow[_currentIndex]["index"];
          }

          emit(SignupInitial(buttonText: "Next", currentIndex: _currentIndex, progessBarIndex: _progressBarIndex));
        } else {
          emit(SingupPhotoUploadError(message: 'Face not detected or multiple faces detected in the first image.'));
          emit(SignupInitial(buttonText: "Retry Upload", currentIndex: _currentIndex, progessBarIndex: _progressBarIndex));
        }
      } catch (e) {
        emit(SingupPhotoUploadError(message: 'Some error occured, try again.'));
        emit(SignupInitial(buttonText: "Retry Upload", currentIndex: _currentIndex, progessBarIndex: _progressBarIndex));
      }
    } else {
      emit(SignupInitial(buttonText: "Upload Photos", currentIndex: _currentIndex, progessBarIndex: _progressBarIndex - 1));
    }
  }
}
