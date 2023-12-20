

/*************************************************************           
 ** File:   [AutoCompleteDropdownsItemMaster]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used retrieve workorder List All for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   04/02/2020      
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/02/2020   subhash Saliya Created
     
--EXEC [AutoCompleteDropdownsWorkorderListbyall] '',20,'108,109,11',1
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsWorkorderListbyall]
@StartWith VARCHAR(50),
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int,
@managementStructureId bigint = 0

AS
	BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
	BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN
				DECLARE @workorderstatusid int;	
				--select @workorderstatusid=Id from  dbo.WorkOrderStatus where  lower(Description)= LOWER('open')
				IF(@Count = '0') 
				   BEGIN
				   SET @Count='20';	
				END	
				SELECT DISTINCT TOP 20 
					wo.WorkOrderId AS Value, 
					wo.WorkOrderNum AS Label
				FROM dbo.WorkOrder wo WITH(NOLOCK) 	
				LEFT JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.EmployeeId = wo.EmployeeId	
				WHERE (wo.IsActive=1 AND ISNULL(wo.IsDeleted,0)=0  and EMS.ManagementStructureId =@managementStructureId   and wo.WorkOrderStatusId not in (select Id from  dbo.WorkOrderStatus where  lower(Description) in ('closed','canceled'))
								  AND wo.MasterCompanyId = @MasterCompanyId AND (wo.WorkOrderNum LIKE @StartWith + '%' OR wo.WorkOrderNum  LIKE '%' + @StartWith + '%'))    
				UNION     
				SELECT 
					wo.WorkOrderId AS Value, 
					wo.WorkOrderNum AS Label
				FROM dbo.WorkOrder wo WITH(NOLOCK) 
				WHERE wo.WorkOrderId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))
				ORDER BY Label			
			--END
		--COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			 --   IF @@trancount > 0
				--PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsWorkorderListbyall'               
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))			  
			   + '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))  
			   + '@Parameter4 = ''' + CAST(ISNULL(@managementStructureId, '') as varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
END