CREATE PROCEDURE [dbo].[SearchSpeedQuotePNViewData]
	-- Add the parameters for the stored procedure here
	@PageNumber int=1,
	@PageSize int=10,
	@SortColumn varchar(50)='',
	@SortOrder int=1,
	@StatusID int=1,
	@GlobalFilter varchar(50) = '',
	--@SOQNumber varchar(50)=null,
	@SpeedQuoteNumber varchar(50)='',
	@CustomerName varchar(50)='',
	@CustomerCode varchar(50)='',
	@Status varchar(50)='',
    @QuoteAmount numeric(18,4)=null,
    @SoAmount numeric(18,4)=null,
    @QuoteDate datetime=null,
    @SalesPerson varchar(50)='',
    --@PriorityType varchar(50)='',
    @PartNumberType varchar(50)='',
    @PartDescriptionType varchar(50)='',
    @CustomerReference varchar(50)='',
    @CustomerType varchar(50)='',
	@VersionNumber varchar(50)='',
    @CreatedDate datetime='',
    @UpdatedDate  datetime='',
	@CreatedBy  varchar(50)='',
	@UpdatedBy  varchar(50)='',
    @IsDeleted bit= 0,
	@MasterCompanyId int = 1,
	@LeadSourceName varchar(50)='',
	@Probability varchar(50)='',
	@QuoteExpireDate datetime=null,
	@AccountTypeName varchar(50)='',
	@LeadSourceReference varchar(50)='',
	@ConditionCodeType varchar(50)='',
	@EmployeeId bigint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @RecordFrom int;
					SET @RecordFrom = (@PageNumber-1)*@PageSize;
					IF @IsDeleted is null
					Begin
						Set @IsDeleted=0
					End
					print @IsDeleted	
					IF @SortColumn is null
					Begin
						Set @SortColumn=Upper('CreatedDate')
					End 
					Else
					Begin 
						Set @SortColumn=Upper(@SortColumn)
					End

					If @QuoteAmount=0
					Begin 
						Set @QuoteAmount=null
					End
					
					If @SoAmount=0
					Begin 
						Set @SoAmount=null
					End


					If @StatusID=0
					Begin 
						Set @StatusID=null
					End 

					If @Status='0'
					Begin
						Set @Status=null
					End
					DECLARE @MSModuleID INT = 27; -- Speed Quote Management Structure Module ID
				-- Insert statements for procedure here
				;With Result AS(
				Select DISTINCT SOQ.SpeedQuoteId,SOQ.SpeedQuoteNumber,SOQ.OpenDate as 'QuoteDate',C.CustomerId,C.Name as 'CustomerName',C.CustomerCode, MST.Name as 'Status',
				--ISNULL(SP.NetSales,0) as 'QuoteAmount',
				ISNULL(SP.UnitSalePrice,0) as 'QuoteAmount',
				SOQ.CreatedDate,SOQ.IsNewVersionCreated,SOQ.StatusId,SOQ.CustomerReference,
				--IsNull(P.Description,'') as 'Priority',IsNull(P.Description,'') as 'PriorityType',
				(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber',IsNull(IM.partnumber,'') as 'PartNumberType',IsNull(im.PartDescription,'') as 'PartDescription',IsNull(im.PartDescription,'') as 'PartDescriptionType',
				Ct.CustomerTypeName as 'CustomerType',
				--SOP.NetSales as 'SoAmount',
				--SOP.UnitSalePrice as 'SoAmount',
				SOQ.QuoteExpireDate,SOQ.AccountTypeName,SOQ.LeadSourceReference,
				SOQ.LeadSourceName,P.PercentValue as 'Probability',
				SOQ.UpdatedDate,SOQ.UpdatedBy, SOQ.CreatedBy,SOQ.IsDeleted,dbo.GenearteVersionNumber(SOQ.Version) as 'VersionNumber',cn.Code as 'ConditionCode', cn.Code as 'ConditionCodeType'
				--,(select count(*) fron SpeedQuoteExclusionPart spe where spe.SpeedQuoteId = SOQ.SpeedQuoteId) as 'count'
				from SpeedQuote SOQ WITH (NOLOCK)
				Inner Join MasterSpeedQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId=MST.Id
				Inner Join Customer C WITH (NOLOCK) on C.CustomerId=SOQ.CustomerId
				Inner Join CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SOQ.AccountTypeId
				Left Join SpeedQuotePart SP WITH (NOLOCK) on SOQ.SpeedQuoteId=SP.SpeedQuoteId and SP.IsDeleted=0
				Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId
				Left Join Employee E WITH (NOLOCK) on  E.EmployeeId=SOQ.SalesPersonId --and SOQ.SalesPersonId is not null
				Left join [Percent] p WITH (NOLOCK) on P.PercentId = SOQ.ProbabilityId
				Left join [Condition] cn WITH (NOLOCK) on cn.ConditionId = SP.ConditionId
				--Left join SpeedQuoteExclusionPart spe on spe.SpeedQuoteId = SOQ.SpeedQuoteId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SpeedQuoteId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				Where (SOQ.IsDeleted=@IsDeleted) and (@StatusID is null or SOQ.StatusId=@StatusID) AND SOQ.MasterCompanyId = @MasterCompanyId),
				FinalResult AS (SELECT SpeedQuoteId,SpeedQuoteNumber,QuoteDate,CustomerId,CustomerName,CustomerCode,Status,VersionNumber,QuoteAmount,IsNewVersionCreated,StatusId
			,CustomerReference,
			--Priority,PriorityType,
			SalesPerson,PartNumber,PartNumberType,PartDescription,PartDescriptionType,CustomerType,
			--SalesOrderNumber,
			--SoAmount,
			QuoteExpireDate,AccountTypeName,LeadSourceReference,
			LeadSourceName,Probability,CreatedDate,UpdatedDate, CreatedBy,UpdatedBy,ConditionCode,ConditionCodeType from Result
				Where (
					(@GlobalFilter <>'' AND ((SpeedQuoteNumber like '%' +@GlobalFilter+'%' ) OR 
							--(SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(CustomerCode like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							--(PriorityType like '%' +@GlobalFilter+'%') OR
							(PartNumberType like '%' +@GlobalFilter+'%') OR
							(PartDescriptionType like '%' +@GlobalFilter+'%') OR
							(CustomerReference like '%' +@GlobalFilter+'%') OR
							(@VersionNumber like '%'+@GlobalFilter+'%') OR
							(CustomerType like '%' +@GlobalFilter+'%') OR 
							(CreatedBy like '%' +@GlobalFilter+'%') OR
							(UpdatedBy like '%' +@GlobalFilter+'%') OR
							(LeadSourceName like '%' +@GlobalFilter+'%') OR
							(Probability like '%' +@GlobalFilter+'%') OR
							(AccountTypeName like '%' +@GlobalFilter+'%') OR
							(LeadSourceReference like '%' +@GlobalFilter+'%') OR
							(ConditionCodeType like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@SpeedQuoteNumber,'') ='' OR SpeedQuoteNumber like  '%'+ @SpeedQuoteNumber+'%') and 
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@CustomerCode,'') ='' OR CustomerCode like  '%'+@CustomerCode+'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and
							(@QuoteAmount is  null or QuoteAmount=@QuoteAmount) and
							--(@SoAmount is  null or SoAmount=@SoAmount) and
							(@QuoteDate is  null or Cast(QuoteDate as date)=Cast(@QuoteDate as date)) and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@PartNumberType,'') ='' OR PartNumberType like '%'+@PartNumberType+'%') and
							(IsNull(@PartDescriptionType,'') ='' OR PartDescriptionType like '%'+@PartDescriptionType+'%') and
							(IsNull(@CustomerReference,'') ='' OR CustomerReference like '%'+@CustomerReference+'%') and
							(IsNull(@CustomerType,'') ='' OR CustomerType like '%'+@CustomerType+'%') and
							(IsNull(@VersionNumber,'') ='' OR VersionNumber like '%'+@VersionNumber+'%') and
							(IsNull(@LeadSourceName,'') ='' OR LeadSourceName like  '%'+@LeadSourceName+'%') and
							(IsNull(@Probability,'') ='' OR Probability like  '%'+@Probability+'%') and
							(IsNull(@QuoteExpireDate,'') ='' OR Cast(QuoteExpireDate as Date)=Cast(@QuoteExpireDate as date)) and
							(IsNull(@AccountTypeName,'') ='' OR AccountTypeName like  '%'+@AccountTypeName+'%') and
							(IsNull(@LeadSourceReference,'') ='' OR LeadSourceReference like  '%'+@LeadSourceReference+'%') and
							(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%'+ @CreatedBy+'%') and
							(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%'+ @UpdatedBy+'%') and
							(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and
							(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and
							(IsNull(@ConditionCodeType,'') ='' OR ConditionCodeType like  '%'+@ConditionCodeType+'%'))
							)),
					ResultCount AS (Select COUNT(SpeedQuoteId) AS NumberOfItems FROM FinalResult)
					SELECT SpeedQuoteId,SpeedQuoteNumber,QuoteDate,CustomerId,CustomerName,CustomerCode,Status,VersionNumber,QuoteAmount,IsNewVersionCreated,StatusId
					,CustomerReference,
					--Priority,
					--PriorityType,
					SalesPerson,PartNumber,PartNumberType,PartDescription,PartDescriptionType,CustomerType,
					--SalesOrderNumber,
					QuoteExpireDate,AccountTypeName,LeadSourceReference,
					LeadSourceName,Probability,
					CreatedDate,UpdatedDate, CreatedBy,UpdatedBy, NumberOfItems,ConditionCode,ConditionCodeType from FinalResult, ResultCount
				ORDER BY  
				 CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SPEEDQUOTENUMBER')  THEN SpeedQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEADSOURCEANAME')  THEN LeadSourceName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PROBABILITY')  THEN Probability END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEEXPIREDATE')  THEN QuoteExpireDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ACCOUNTTYPENAME')  THEN AccountTypeName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEADSOURCEREFERENCE')  THEN LeadSourceReference END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CONDITIONCODETYPE')  THEN ConditionCodeType END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEADSOURCEANAME')  THEN LeadSourceName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PROBABILITY')  THEN Probability END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEEXPIREDATE')  THEN QuoteExpireDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ACCOUNTTYPENAME')  THEN AccountTypeName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEADSOURCEREFERENCE')  THEN LeadSourceReference END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CONDITIONCODETYPE')  THEN ConditionCodeType END Desc
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
					Print @SortOrder

			END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchSpeedQuotePNViewData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''
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