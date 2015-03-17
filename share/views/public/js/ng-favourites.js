var rbbt_angular = angular.module('rbbt', [])

rbbt_angular.controller('FavourtiesController', ['$scope', function($scope){
 $scope.favourite = 'not_favourite'; 
 $scope.toggle = function(){
  if ($scope.favourite == 'favourite'){
   $scope.favourite = 'not_favourite'
  }else{
   $scope.favourite = 'favourite'
  }
 }
}]);

