/*************************************************************     
-- EXEC [dbo].[AutoCompleteDropdownsExchangeSalesOrder] 'Exch',1,25,'0,0,0',1
**************************************************************/
CREATE PROCEDURE [dbo].[AutoCompleteDropdownsExchangeSalesOrder]
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
		--BEGIN TRANSACTION
			--BEGIN
				DECLARE @Sql NVARCHAR(MAX);	
				IF(@Count = '0') 
				   BEGIN
				   set @Count='20';	
				END	
				
					SELECT DISTINCT TOP 20 
						c.ExchangeSalesOrderId,
						c.ExchangeSalesOrderNumber
					FROM dbo.ExchangeSalesOrder c
					WHERE (c.IsActive = 1 AND ISNULL(c.IsDeleted, 0) = 0 AND c.MasterCompanyId = @MasterCompanyId AND (c.ExchangeSalesOrderNumber LIKE @StartWith + '%'))
					UNION
					SELECT DISTINCT TOP 20 
						c.ExchangeSalesOrderId,
						c.ExchangeSalesOrderNumber
					FROM dbo.ExchangeSalesOrder c
					WHERE (c.IsActive = 1 AND ISNULL(c.IsDeleted, 0) = 0 AND c.MasterCompanyId = @MasterCompanyId AND (c.ExchangeSalesOrderNumber LIKE @StartWith + '%'))
					AND c.ExchangeSalesOrderId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
					ORDER BY ExchangeSalesOrderNumber
		END TRY    
		BEGIN CATCH      
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
               , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsExchangeSalesOrder' 
			   , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName        = @DatabaseName
                     , @AdhocComments       = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName     =  @ApplicationName
                     , @ErrorLogID          = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END