﻿
/*************************************************************           
 ** File:   [AutoCompleteDropdownsCondition]           
 ** Author:   Subhash Saliya
 ** Description: This SP is used retrieve COndition List for Auto Complete Dropdown With Code
 ** Purpose:         
 ** Date:   09/24/2021     
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/24/2021   Subhash Saliya Created
     
--EXEC [AutoCompleteDropdownsTraveler_Instruction] '',1,20,'0',1
**************************************************************/

CREATE     PROCEDURE [dbo].[AutoCompleteDropdownsTraveler_Task]
@StartWith VARCHAR(50),
@IsActive bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY  

		DECLARE @Sql NVARCHAR(MAX);	

		IF(@Count = '0') 
		   BEGIN
		   SET @Count='20';	
		END	
		IF(@IsActive = 1)
			BEGIN		
					SELECT DISTINCT TOP 20 
						C.TaskId AS Value, 
						C.Description AS Label,		
						C.Memo AS Notes,
						C.Sequence AS SequenceNo
					FROM dbo.Task C WITH(NOLOCK)
					WHERE C.MasterCompanyId = @MasterCompanyId AND C.IsTravelerTask=1 AND (C.IsActive=1 AND ISNULL(C.IsDeleted,0) = 0 
						AND (C.Description LIKE @StartWith + '%'))
			   UNION     
					SELECT DISTINCT  
						C.TaskId AS Value, 
						C.Description AS Label,		
						C.Memo AS Notes,
						C.Sequence AS SequenceNo
					FROM dbo.Task C WITH(NOLOCK)
					WHERE C.MasterCompanyId = @MasterCompanyId AND C.IsTravelerTask=1 AND C.TaskId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
				ORDER BY Label				
			End
			ELSE
			BEGIN
				SELECT DISTINCT TOP 20 
						C.TaskId AS Value, 
						C.Description AS Label,		
						C.Memo AS Notes,
						C.Sequence AS SequenceNo
					FROM dbo.Task C WITH(NOLOCK)
					WHERE C.MasterCompanyId = @MasterCompanyId AND C.IsTravelerTask=1 AND (ISNULL(C.IsDeleted,0) = 0 
						AND (C.Description LIKE '%' + @StartWith + '%'))
				UNION 
				SELECT DISTINCT  
						C.TaskId AS Value, 
						C.Description AS Label,		
						C.Memo AS Notes,
						C.Sequence AS SequenceNo
					FROM dbo.Task C WITH(NOLOCK)
					WHERE C.MasterCompanyId = @MasterCompanyId AND C.IsTravelerTask=1 AND C.TaskId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  
				ORDER BY Label	
			END	
	END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsTraveler_Task'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))  
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))		
			   + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100)) 
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END