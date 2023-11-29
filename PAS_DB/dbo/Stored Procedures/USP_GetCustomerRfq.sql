/*************************************************************           
 ** File:   [USP_GetCustomerRfq]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used GetCustomerRfq data
 ** Purpose:         
 ** Date:   15/02/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/02/2023  Amit Ghediya    Created
     
-- EXEC USP_GetCustomerRfq 
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerRfq]
	@PageNumber INT,
	@PageSize INT,
	@SortColumn VARCHAR(50)=null,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = null,
	@RfqId VARCHAR(20),
	@RfqCreatedDate DATETIME=null,
	@BuyerCompanyName [VARCHAR](250) NULL,
	@BuyerName [VARCHAR](250) NULL,
	@BuyerCountry [VARCHAR](50) NULL,
	@LinePartNumber [VARCHAR](250) NULL,
	@MasterCompanyId INT,
	@CreatedDate DATETIME=null,
    @UpdatedDate  DATETIME=null,
    @IsDeleted BIT = null,
	@CreatedBy VARCHAR(50)=null,
	@UpdatedBy VARCHAR(50)=null,
	@OrganizationTagTypeName VARCHAR(50) = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			DECLARE @RecordFrom INT;
				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				IF @IsDeleted is null
				BEGIN
					SET @IsDeleted=0
				END
				
				IF @SortColumn is null
				BEGIN
					SET @SortColumn=Upper('CreatedDate')
				END 
				Else
				BEGIN 
					SET @SortColumn=Upper(@SortColumn)
				END
		
			;With Result AS(
				SELECT RFQ.[CustomerRfqId],
					RFQ.[RfqId], 
					RFQ.[RfqCreatedDate] AS 'RfqcreatedDate',
					RFQ.[BuyerName] AS 'rfqFrom',
					RFQ.[BuyerCompanyName] AS 'companyName',
					RFQ.[BuyerCountry] AS 'country',
					RFQ.[LinePartNumber] AS 'partNumber',
					RFQ.[LineDescription] AS 'lineDescription',
					RFQ.[BuyerAddress] AS 'rfqAddress',
					RFQ.[BuyerCity] AS 'rfqCity',
					RFQ.[BuyerCountry] AS 'rfqCountry',
					RFQ.[BuyerState] AS 'rfqState',
					RFQ.[BuyerZip] AS 'rfqZip',
					RFQ.[IsQuote],
					RFQ.CreatedDate, RFQ.UpdatedDate, RFQ.CreatedBy, RFQ.UpdatedBy
				FROM CustomerRfq RFQ WITH (NOLOCK)
				WHERE RFQ.MasterCompanyId = @MasterCompanyId AND RFQ.IsQuote IS NOT NULL),
				FinalResult AS (
				SELECT CustomerRfqId, RfqId, RfqcreatedDate, rfqFrom, companyName, country, partNumber, lineDescription, rfqAddress, rfqCity, rfqCountry, rfqState, rfqZip, IsQuote
					 ,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy FROM Result
				WHERE (
					(@GlobalFilter <>'' AND ((RfqId like '%' +@GlobalFilter+'%') OR 
							(RfqcreatedDate like '%' +@GlobalFilter+'%') OR
							(rfqFrom like '%' +@GlobalFilter+'%') OR
							(companyName like '%' +@GlobalFilter+'%') OR
							(country like '%' +@GlobalFilter+'%') OR
							(partNumber like '%'+@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@RfqId,'') ='' OR CAST(rfqId AS VARCHAR(20)) like '%' + CAST(@RfqId AS VARCHAR(20)) + '%') and 
							(IsNull(@RfqCreatedDate,'') ='' OR Cast(RfqcreatedDate as date)=Cast(RfqcreatedDate as date)) and
							(IsNull(@BuyerName,'') ='' OR rfqFrom like  '%'+@BuyerName+'%') and
							(IsNull(@BuyerCompanyName,'') ='' OR companyName like '%'+@BuyerCompanyName+'%') and
							(IsNull(@BuyerCountry,'') ='' OR country like '%'+ @BuyerCountry+'%') and
							(IsNull(@LinePartNumber,'') ='' OR partNumber like '%'+@LinePartNumber+'%') and
							(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%'+ @CreatedBy+'%') and
							(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%'+ @UpdatedBy+'%') and
							(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and
							(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)))
							)),
						ResultCount AS (Select COUNT(CustomerRfqId) AS NumberOfItems FROM FinalResult)
						SELECT CustomerRfqId, RfqId, RfqcreatedDate,rfqFrom, companyName,country, partNumber,lineDescription,rfqAddress,rfqCity,rfqCountry,rfqState,rfqZip,IsQuote,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,
						NumberOfItems FROM FinalResult, ResultCount

						ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERRFQID')  THEN CustomerRfqId END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='RFQID')  THEN RfqId END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='RFQCREATEDDATE')  THEN RfqcreatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='RFQFROM')  THEN rfqFrom END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='COMPANYNAME')  THEN companyName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='COUNTRY')  THEN country END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN partNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERRFQID')  THEN CustomerRfqId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQID')  THEN RfqId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQCREATEDDATE')  THEN RfqcreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQFROM')  THEN rfqFrom END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='COMPANYNAME')  THEN companyName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='COUNTRY')  THEN country END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN partNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
				END
				COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetCustomerRfq' 
            , @ProcedureParameters VARCHAR(3000) = '@RfqId = ''' + CAST(ISNULL(@RfqId, '') as varchar(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END