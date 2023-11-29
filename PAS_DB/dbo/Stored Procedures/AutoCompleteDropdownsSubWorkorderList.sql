CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsSubWorkorderList]
@StartWith VARCHAR(50),
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int

AS
	BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
	BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN
				IF(@Count = '0') 
				   BEGIN
				   SET @Count='20';	
				END	
				SELECT DISTINCT TOP 20 
					swo.SubWorkOrderId AS Value, 
					swo.SubWorkOrderNo AS Label
				FROM dbo.SubWorkOrder swo WITH(NOLOCK) 						
				WHERE (swo.IsActive=1 AND ISNULL(swo.IsDeleted,0)=0
								  AND swo.MasterCompanyId = @MasterCompanyId AND (swo.SubWorkOrderNo LIKE @StartWith + '%' OR swo.SubWorkOrderNo  LIKE '%' + @StartWith + '%'))    
				UNION     
				SELECT 
					swo.SubWorkOrderId AS Value, 
					swo.SubWorkOrderNo AS Label
				FROM dbo.SubWorkOrder swo WITH(NOLOCK)  
				WHERE swo.SubWorkOrderId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
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
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsSubWorkorderList'               
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))			  
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
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