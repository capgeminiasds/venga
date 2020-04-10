import { Action } from '@ngrx/store';

export enum UIActionType {
  CLEAR_ERROR = '[UI] Clear Error',
  SET_LOADING_STATE = '[UI] Set Loading State',
}

export class ClearError implements Action {
  public readonly type: string = UIActionType.CLEAR_ERROR;
}

export type UIActions = ClearError;


 import { Injectable } from '@angular/core';
import { Actions, Effect, ofType } from '@ngrx/effects';
import { forkJoin, of } from 'rxjs';
import { switchMap, map, catchError } from 'rxjs/operators';

import { UserActions, UserActionTypes, LoadUsersSuccess, LoadUsersFailure } from '../actions/user.actions';
import { CoreService } from '../../services/core.service';

@Injectable()
export class UserEffects {

  constructor(private actions$: Actions<UserActions>, private core: CoreService) { }

  @Effect()
  loadUser$ = this.actions$.pipe(
    ofType(UserActionTypes.LoadUser),
    switchMap(() =>
      this.core.getCurrentUser().pipe(map((user) => new LoadUsersSuccess(user)),
        catchError((error) => of(new LoadUsersFailure(error)))
      )
    )
  );

}
import { Injectable } from '@angular/core';
import { map, catchError, switchMap, withLatestFrom } from 'rxjs/operators';
import { of } from 'rxjs';
import { Store, select } from '@ngrx/store';
import { Actions, ofType, Effect } from '@ngrx/effects';
import {
  ViolationActions,
  ViolationActionTypes,
  GetViolationGridDataSuccess,
  GetViolationGridDataFailed,
  GetSingleUserViolationDataSuccess,
  GetSingleUserViolationDataFailed
} from '../actions/violation.actions';
import { CoreService } from '../../services/core.service';
import { AppState } from '../reducers';
import { getBUId } from '../selectors/violation.selectors';




@Injectable()
export class ViolationsEffects {

  constructor(private actions$: Actions<ViolationActions>, private core: CoreService, private store: Store<AppState>) { }

  @Effect()
  violationGridData$ = this.actions$.pipe(
    ofType(ViolationActionTypes.GetViolationGridData),
    switchMap((action) =>
      this.core.getViolationGridData(action.payload).pipe(map((data) => new GetViolationGridDataSuccess(data)),
        catchError((error) => of(new GetViolationGridDataFailed(error)))
      )
    )
  );

  @Effect()
  singleUserViolation$ = this.actions$.pipe(
    ofType(ViolationActionTypes.GetSingleUserViolationData),
    withLatestFrom(this.store.pipe(select(getBUId))),
    switchMap(([action, buId]) =>
      this.core.getSingleUserViolationData(action.payload, buId).pipe(map((data) => new GetSingleUserViolationDataSuccess(data)),
        catchError((error) => of(new GetSingleUserViolationDataFailed(error)))
      )
    )
  );
}
import {
  ViolationActions,
  ViolationActionTypes,
  GetViolationGridDataSuccess,
  GetSingleUserViolationDataSuccess
} from '../actions/violation.actions';
import { GroupMap, SingleUserReview } from '../../model/employee.model';


export const populationFeatureKey = 'violation';

export interface ViolationState {
  gridData: GroupMap;
  singleUser: SingleUserReview;
}

export const initialState: ViolationState = {
  gridData: null,
  singleUser: null
};

export function reducer(state = initialState, action: ViolationActions): ViolationState {
  switch (action.type) {
    case ViolationActionTypes.GetViolationGridDataSuccess:
      return {
        ...state,
        gridData: (action as GetViolationGridDataSuccess).payload
      };
    case ViolationActionTypes.GetSingleUserViolationDataSuccess:
      return {
        ...state,
        singleUser: (action as GetSingleUserViolationDataSuccess).payload
      };

    default:
      return state;
  }
}


import { createFeatureSelector, MemoizedSelector, createSelector } from '@ngrx/store';
import { AppState } from '../reducers';
import { ViolationState } from '../reducers/violation.reducer';
import { User, SingleUserReview } from '../../model/employee.model';

export const selectViolation: MemoizedSelector<AppState, ViolationState> = createFeatureSelector<AppState, ViolationState>('violation');


export const getViolationGridCombinedData: MemoizedSelector<AppState, User[]> = createSelector(
  selectViolation,
  (state: ViolationState) => state.gridData && state.gridData.users ?
  state.gridData.users.filter(u => u.violationInd === 'Not a Violation' || u.violationInd === 'Violation') : []
);

export const getAllViolationsCount: MemoizedSelector<AppState, number> = createSelector(
  selectViolation,
  (state: ViolationState) => state.gridData && state.gridData.users ?
  state.gridData.users.filter(u => u.violationInd === 'Not a Violation' || u.violationInd === 'Violation').length : 0
);

export const getReviewedViolationsCount: MemoizedSelector<AppState, number> = createSelector(
  selectViolation,
  (state: ViolationState) => state.gridData && state.gridData.users ?
  state.gridData.users.filter(u => u.reviewedInd === '1').length : 0
);

export const getBUId: MemoizedSelector<AppState, string> = createSelector(
  selectViolation,
  (state: ViolationState) => state && state.gridData ? state.gridData.id : ''
);

export const getSingleUserViolationReview: MemoizedSelector<AppState, SingleUserReview> = createSelector(
  selectViolation,
  (state: ViolationState) => state && state.singleUser ? state.singleUser : null
);
import { Injectable } from '@angular/core';
import { Store, select } from '@ngrx/store';
import { Observable } from 'rxjs';

import { AppState } from '../store/reducers';
import { LoadUser } from '../store/actions/user.actions';
import * as userSelector from '../store/selectors/user.selector';
import * as uiSelector from '../store/selectors/ui.selector';
import * as populationSelector from '../store/selectors/population.selectors';
import * as violationSelector from '../store/selectors/violation.selectors';
import { Option, User, SingleUserReview } from '../model/employee.model';
import { GetPopulationGridData } from '../store/actions/population.actions';
import { GetViolationGridData, GetSingleUserViolationData } from '../store/actions/violation.actions';

@Injectable({
  providedIn: 'root'
})
export class StoreService {

  constructor(private store: Store<AppState>) { }

  public initialize = (): void => this.store.dispatch(new LoadUser());

  public isLoading = (): Observable<boolean> => this.store.pipe(select(uiSelector.isLoading));

  public isBuAdmin = (): Observable<boolean> => this.store.pipe(select(userSelector.isBuAdmin));

  public isHelpDeskAdmin = (): Observable<boolean> => this.store.pipe(select(userSelector.isHelpDeskAdmin));

  public getBUData = (): Observable<Option[]> => this.store.pipe(select(userSelector.getBuData));

  public getPopulationGridData = (regionId: string): void => this.store.dispatch(new GetPopulationGridData(regionId));

  public getReviewedPopulationGridData = (): Observable<User[]> =>
    this.store.pipe(select(populationSelector.getReviewedPopulationGridData))

  public getPendingPopulationGridData = (): Observable<User[]> =>
    this.store.pipe(select(populationSelector.getPendingPopulationGridData))

  public getInScopeCount = (): Observable<number> => this.store.pipe(select(populationSelector.getInScopeCount));

  public getAllUsersCount = (): Observable<number> => this.store.pipe(select(populationSelector.getAllUsersCount));

  public getDatesEnteredByIncluded = (): Observable<number> => this.store.pipe(select(populationSelector.getDatesEnteredByIncluded));

  public getPopulationSelectedBU = (): Observable<string> => this.store.pipe(select(populationSelector.getPopulationSelectedBU));

  public getViolationGridData = (review: any): any => this.store.dispatch(new GetViolationGridData(review));

  public getViolationGridCombinedData = (): Observable<User[]> => this.store.pipe(select(violationSelector.getViolationGridCombinedData));

  public getReviewedViolationsCount = (): Observable<number> => this.store.pipe(select(violationSelector.getReviewedViolationsCount));

  public getAllViolationsCount = (): Observable<number> => this.store.pipe(select(violationSelector.getAllViolationsCount));

  public getSingleUserViolationData = (data: User): void => this.store.dispatch(new GetSingleUserViolationData(data));

  public fetchSingleUserViolationData = (): Observable<SingleUserReview> =>
    this.store.pipe(select(violationSelector.getSingleUserViolationReview))

}
