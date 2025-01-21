import 'package:bloc/bloc.dart';
import '../Network/ApiProvider.dart';
import 'native_item_event.dart';
import 'native_item_state.dart';

class NativeItemBloc extends Bloc<NativeItemEvent, NativeItemState> {
  final ApiProvider _apiRepository = ApiProvider();

  NativeItemBloc() : super(NativeItemInitial()) {
   /* on<GetMenuDetailsEvents>((event, emit) async {
      try {
        final mList = await _apiRepository.fetchMenuDetails();

        if (mList != null) {
          emit(NativeItemLoaded(mList));
        } else {
          emit(NativeItemError('List Getting empty'));
        }
      } catch (error) {
        emit(NativeItemError(error.toString()));
      }
    });*/


    on<GetAppDeailsDetailsEvents>((event, emit) async {
      try {
        final mList = await _apiRepository.fetchAppConfig();

        print("dtailsEvertn : ${mList}");
        emit(AppConfigItemLoaded(mList));

            } catch (error) {
        print("dtailsEvertn : ${error}");

        emit(AppConfigItemError(error.toString()));
      }
    });


  }
}
